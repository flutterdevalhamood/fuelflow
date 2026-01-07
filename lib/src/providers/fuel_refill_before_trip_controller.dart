import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelRefillBeforeTripController extends ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingRefill = false;
  String? errorMessage;
  String? successMessage;
  int? lastStockEventId;

  Future<bool> postFuelVehicleWithMeterReading({
    required int vehicleId,
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
    String? note,
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

      debugPrint('🚀 Submitting fuel refill...');

      // Prepare multipart files
      Future<List<MultipartFile>> prepareFiles(List<File> files) async {
        if (files.isEmpty) return [];
        return await Future.wait(
          files.map(
            (file) async => await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      // ✅ FIXED: Prepare CUSTOMER meter files instead of vehicle files
      final customerStartFiles = await prepareFiles(customerStartMeterFiles);
      final customerEndFiles = await prepareFiles(customerEndMeterFiles);
      final vehicleStartFiles = await prepareFiles(vehicleStartMeterFiles);
      final vehicleEndFiles = await prepareFiles(vehicleEndMeterFiles);

      debugPrint(
        '📁 Prepared ${customerStartFiles.length} customer start photos',
      );
      debugPrint('📁 Prepared ${customerEndFiles.length} customer end photos');
      debugPrint(
        '📁 Prepared ${vehicleStartFiles.length} vehicle start photos',
      );
      debugPrint('📁 Prepared ${vehicleEndFiles.length} vehicle end photos');

      final response = await RestClient(Dio()).postFuelVehicleWithMeterReading(
        token: 'Bearer $token',
        vehicleId: vehicleId,
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
        // ✅ FIXED: Pass customer meter readings and files
        customerStartMeterReadingValue: customerStartMeterReadingValue,
        customerStartMeterFiles: customerStartFiles,
        customerEndMeterReadingValue: customerEndMeterReadingValue,
        customerEndMeterFiles: customerEndFiles,
      );

      debugPrint('✅ API Response received');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint(
            '🔍 Vehicle Tank Start Reading: $vehicleTankStartReadingValue',
          );
          debugPrint(
            '🔍 Vehicle Tank End Reading: $vehicleTankEndReadingValue',
          );
          debugPrint('🔍 Vehicle Start Files: ${vehicleStartFiles.length}');
          debugPrint('🔍 Vehicle End Files: ${vehicleEndFiles.length}');

          successMessage =
              response['Message'] ?? 'Fuel refill completed successfully';

          // Extract stock event ID
          if (response['Data'] is int) {
            lastStockEventId = response['Data'] as int;
          } else if (response['Data'] is Map<String, dynamic> &&
              response['Data']['stock_event_id'] != null) {
            lastStockEventId = response['Data']['stock_event_id'] as int;
          }

          debugPrint('🎉 Refill successful. Stock Event ID: $lastStockEventId');

          isSubmittingRefill = false;
          notifyListeners();
          return true;
        } else {
          errorMessage = response['Message'] ?? 'Failed to complete refill';
          debugPrint('❌ API Error: $errorMessage');
        }
      } else {
        errorMessage = 'Unexpected response format';
        debugPrint('❌ Unexpected response: $response');
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');

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
