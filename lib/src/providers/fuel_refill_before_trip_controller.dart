import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
// Import the helper

class FuelRefillBeforeTripController extends ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingRefill = false;
  String? errorMessage;
  String? successMessage;
  int? lastStockEventId;

  Future<List<Map<String, dynamic>>> getRefillingStatusForStop({
    required String tripId,
    required int tripStopId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = AuthRepo.token;
      if (token == null) {
        throw Exception("No authentication token found");
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await RestClient(dio).getRefillingStatusForStop(
        token: 'Bearer $token',
        tripId: tripId,
        tripStopId: tripStopId,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'];

        if (data != null && data['trip_stops'] is List) {
          final tripStops = data['trip_stops'] as List;

          // Find the matching trip stop
          final matchingStop = tripStops.firstWhere(
            (stop) => stop['stop_id'] == tripStopId,
            orElse: () => null,
          );

          if (matchingStop != null && matchingStop['stop_vehicles'] is List) {
            final stopVehicles = matchingStop['stop_vehicles'] as List;

            // Filter vehicles that have been refueled (status = "1" and has refueling data)
            final refilledVehicles =
                stopVehicles
                    .where(
                      (vehicle) =>
                          vehicle['status'] == "1" &&
                          vehicle['refueling'] != null,
                    )
                    .map(
                      (vehicle) => {
                        'plate_no': vehicle['plate_no'],
                        'quantity': vehicle['refueling']['quantity'],
                        'before_quantity':
                            vehicle['refueling']['before_quantity'],
                        'after_quantity':
                            vehicle['refueling']['after_quantity'],
                        'note': vehicle['refueling']['note'],
                        'created_at': vehicle['refueling']['created_at'],
                      },
                    )
                    .toList();

            isLoading = false;
            notifyListeners();
            return List<Map<String, dynamic>>.from(refilledVehicles);
          }
        }
      } else {
        errorMessage =
            response['Message'] ?? 'Failed to fetch refilling status';
      }
    } catch (e) {
      errorMessage = 'Failed to load refilling status';
    }

    isLoading = false;
    notifyListeners();
    return [];
  }

  Future<bool> postFuelVehicleWithMeterReading({
    required int vehicleId,
    int? stopVehicleId,
    required String tripId,
    required int tripStopId,
    required String type,
    required double quantity,
    required double beforeQuantity,
    required double afterQuantity,
    required int customerStartMeterReadingValue,
    required List<File> customerStartMeterFiles,
    required int customerEndMeterReadingValue,
    required List<File> customerEndMeterFiles,
    required int vehicleTankStartReadingValue,
    required List<File> vehicleStartMeterFiles,
    required int vehicleTankEndReadingValue,
    required List<File> vehicleEndMeterFiles,
    List<File>? additionalFiles,
    String? note,
    void Function(int sent, int total)? onUploadProgress,
  }) async {
    isSubmittingRefill = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final token = AuthRepo.token;
      if (token == null) {
        throw Exception("No authentication token found");
      }

      // AFTER (fast - reads all bytes into memory first, in parallel):
      Future<List<MultipartFile>> prepareFiles(List<File> files) async {
        if (files.isEmpty) return [];
        return await Future.wait(
          files.map((file) async {
            // Read bytes upfront so Dio doesn't do disk I/O mid-upload
            final bytes = await file.readAsBytes();
            return MultipartFile.fromBytes(
              bytes,
              filename: file.path.split('/').last,
            );
          }),
        );
      }

      // All file groups read in parallel before the request even starts
      final fileResults = await Future.wait([
        prepareFiles(customerStartMeterFiles),
        prepareFiles(customerEndMeterFiles),
        prepareFiles(vehicleStartMeterFiles),
        prepareFiles(vehicleEndMeterFiles),
        prepareFiles(additionalFiles ?? []),
      ]);

      final customerStartFiles = fileResults[0];
      final customerEndFiles = fileResults[1];
      final vehicleStartFiles = fileResults[2];
      final vehicleEndFiles = fileResults[3];
      final additionalMultipartFiles = fileResults[4];

      // Create Dio with proper timeout configuration
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      final stopVehicleIdString = (stopVehicleId ?? 0).toString();

      final response = await RestClient(dio).postFuelVehicleWithMeterReading(
        token: 'Bearer $token',
        vehicleId: vehicleId,
        stopVehicleId: stopVehicleIdString,
        tripId: tripId,
        tripStopId: tripStopId,
        inFlow: type,
        quantity: quantity.toStringAsFixed(2),
        beforeQuantity: beforeQuantity.toStringAsFixed(2),
        afterQuantity: afterQuantity.toStringAsFixed(2),
        note: note ?? '',
        vehicleTankStartReadingValue: vehicleTankStartReadingValue,
        vehicleStartMeterFiles: vehicleStartFiles,
        vehicleTankEndReadingValue: vehicleTankEndReadingValue,
        vehicleEndMeterFiles: vehicleEndFiles,
        customerStartMeterReadingValue: customerStartMeterReadingValue,
        customerStartMeterFiles: customerStartFiles,
        customerEndMeterReadingValue: customerEndMeterReadingValue,
        customerEndMeterFiles: customerEndFiles,
        additionalFiles: additionalMultipartFiles,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          successMessage =
              response['Message'] ?? 'Fuel refill completed successfully';

          // Extract stock event ID
          if (response['Data'] is int) {
            lastStockEventId = response['Data'] as int;
          } else if (response['Data'] is Map<String, dynamic> &&
              response['Data']['stock_event_id'] != null) {
            lastStockEventId = response['Data']['stock_event_id'] as int;
          }

          isSubmittingRefill = false;
          notifyListeners();
          return true;
        } else {
          errorMessage = response['Message'] ?? 'Failed to complete refill';
        }
      } else {
        errorMessage = 'Unexpected response format';
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response?.data;
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['Message'] ??
                errorData['message'] ??
                'Server error occurred';
          } else if (errorData is String) {
            errorMessage = errorData;
          } else {
            errorMessage =
                'Server responded with error: ${e.response?.statusCode}';
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server timeout. Please try again.';
        } else if (e.type == DioExceptionType.sendTimeout) {
          errorMessage = 'Upload timeout. Images may be too large.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'No internet connection. Please check your network.';
        } else {
          errorMessage = 'Network error: ${e.message}';
        }
      } else {
        errorMessage = 'An unexpected error occurred: $e';
      }
    }

    isSubmittingRefill = false;
    notifyListeners();
    return false;
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void reset() {
    isLoading = false;
    isSubmittingRefill = false;
    errorMessage = null;
    successMessage = null;
    lastStockEventId = null;
    notifyListeners();
  }
}
