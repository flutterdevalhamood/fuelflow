import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelRefillBeforeTripControllerController with ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingRefill = false;
  bool isSubmittingMeterReading = false;
  final token = AuthRepo.token;
  String? errorMessage;
  String? successMessage;

  // Refill data
  Map<String, dynamic>? lastRefillData;
  int? lastStockEventId;

  /// Post fuel vehicle refill (depot tank to vehicle tank)
  Future<bool> postFuelVehicleRefill({
    required int vehicleId,
    required String tripId,
    required int tripStopId,
    required String type,
    required num quantity,
    required num beforeQuantity,
    required num afterQuantity,
    String? note,
  }) async {
    isSubmittingRefill = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No token found");
      }

      final response = await restApi.postFuelVehicle(
        token: 'Bearer $token',
        vehicleId: vehicleId,
        tripId: tripId,
        tripStopId: tripStopId,
        inFlow: type,
        quantity: quantity.toStringAsFixed(2),
        beforeQuantity: beforeQuantity.toStringAsFixed(2),
        afterQuantity: afterQuantity.toStringAsFixed(2),
        note: note,
      );

      print('Fuel Vehicle Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          // The response Data is the stock_event_id (integer)
          if (response['Data'] is int) {
            lastStockEventId = response['Data'] as int;
            lastRefillData = {'stock_event_id': lastStockEventId};
            print('✅ Stock Event ID saved: $lastStockEventId');
          } else if (response['Data'] is Map<String, dynamic>) {
            lastRefillData = response['Data'] as Map<String, dynamic>;
            if (lastRefillData!.containsKey('stock_event_id')) {
              lastStockEventId = lastRefillData!['stock_event_id'] as int?;
              print('✅ Stock Event ID saved: $lastStockEventId');
            }
          }

          successMessage =
              response['Message'] ?? 'Fuel refill completed successfully';
          isSubmittingRefill = false;
          notifyListeners();
          return true;
        } else {
          errorMessage =
              response['Message'] ?? 'Failed to complete fuel refill';
          print('API call failed: ${response['Message']}');
          isSubmittingRefill = false;
          notifyListeners();
          return false;
        }
      } else {
        errorMessage = 'Unexpected API response format';
        print('Unexpected API response format');
        isSubmittingRefill = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to complete fuel refill';
      print('Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        if (e.response != null) {
          print('Response data: ${e.response?.data}');
        }
      }
      isSubmittingRefill = false;
      notifyListeners();
      return false;
    }
  }

  /// Store meter reading event
  /// readingType: 'vehicle_tank_start', 'vehicle_tank_end', 'customer_start_meter', 'customer_end_meter'
  Future<bool> postStoreMeterReadingEvent({
    int? stockEventId,
    required String readingType,
    int? tripStopId,
    required int vehicleId,
    required num readingValue,
    String? note,
    List<File>? photoFiles,
  }) async {
    isSubmittingMeterReading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No token found");
      }

      // Use provided stockEventId or fallback to lastStockEventId
      final eventId = stockEventId ?? lastStockEventId;

      if (eventId == null) {
        throw Exception("Stock event ID is required");
      }

      print('📊 Submitting meter reading:');
      print('   - Reading Type: $readingType');
      print('   - Stock Event ID: $eventId');
      print('   - Vehicle ID: $vehicleId');
      print('   - Trip Stop ID: $tripStopId');
      print('   - Reading Value: $readingValue');

      // Convert File objects to MultipartFile
      List<MultipartFile>? multipartFiles;
      if (photoFiles != null && photoFiles.isNotEmpty) {
        multipartFiles = [];
        for (var file in photoFiles) {
          final fileName = file.path.split('/').last;
          final multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
          multipartFiles.add(multipartFile);
        }
        print('   - Photos: ${multipartFiles.length} file(s)');
      }

      final response = await restApi.postStoreMeterReading(
        token: 'Bearer $token',
        stockEventId: eventId,
        readingType: readingType,
        tripStopId: tripStopId,
        vehicleId: vehicleId,
        readingValue: readingValue.toStringAsFixed(2),
        note: note,
        files: multipartFiles,
      );

      print('Store Meter Reading Response ($readingType): $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          successMessage =
              response['Message'] ?? 'Meter reading stored successfully';
          print('✅ $readingType meter reading submitted successfully');
          isSubmittingMeterReading = false;
          notifyListeners();
          return true;
        } else {
          errorMessage = response['Message'] ?? 'Failed to store meter reading';
          print('❌ API call failed: ${response['Message']}');
          isSubmittingMeterReading = false;
          notifyListeners();
          return false;
        }
      } else {
        errorMessage = 'Unexpected API response format';
        print('❌ Unexpected API response format');
        isSubmittingMeterReading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to store meter reading';
      print('❌ Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        if (e.response != null) {
          print('Response data: ${e.response?.data}');
        }
      }
      isSubmittingMeterReading = false;
      notifyListeners();
      return false;
    }
  }

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
    notifyListeners();

    try {
      // Prepare multipart files for customer start meter photos
      List<MultipartFile> startMeterMultipartFiles = [];
      for (var file in customerStartMeterFiles) {
        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        );
        startMeterMultipartFiles.add(multipartFile);
      }

      // Prepare multipart files for customer end meter photos
      List<MultipartFile> endMeterMultipartFiles = [];
      for (var file in customerEndMeterFiles) {
        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        );
        endMeterMultipartFiles.add(multipartFile);
      }

      final response = await restApi.postFuelVehicleWithMeterReading(
        token: 'Bearer ${AuthRepo.token}',
        vehicleId: vehicleId,
        tripId: tripId,
        tripStopId: tripStopId,
        inFlow: type,
        quantity: quantity.toStringAsFixed(2),
        beforeQuantity: beforeQuantity.toStringAsFixed(2),
        afterQuantity: afterQuantity.toStringAsFixed(2),
        note: note ?? '',
        customerStartMeterReadingValue: customerStartMeterReadingValue,
        customerStartMeterFiles: startMeterMultipartFiles,
        customerEndMeterReadingValue: customerEndMeterReadingValue,
        customerEndMeterFiles: endMeterMultipartFiles,
        vehicleTankStartReadingValue: null,
        vehicleStartMeterFiles: null,
        vehicleTankEndReadingValue: null,
        vehicleEndMeterFiles: null,
      );

      debugPrint('✅ Fuel delivery with meter readings completed successfully');
      debugPrint('Response: $response');

      // Extract stock event ID if needed for future use
      if (response != null && response['data'] != null) {
        lastStockEventId = response['data']['id'];
        debugPrint('Stock Event ID: $lastStockEventId');
      }

      isSubmittingRefill = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error posting fuel delivery with meter readings: $e');

      if (e is DioException) {
        if (e.response != null) {
          errorMessage =
              e.response?.data['message'] ?? 'Failed to complete delivery';
          debugPrint('Error response: ${e.response?.data}');
        } else {
          errorMessage = 'Network error. Please check your connection.';
        }
      } else {
        errorMessage = 'An unexpected error occurred';
      }

      isSubmittingRefill = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void reset() {
    isLoading = false;
    isSubmittingRefill = false;
    isSubmittingMeterReading = false;
    errorMessage = null;
    successMessage = null;
    lastRefillData = null;
    lastStockEventId = null;
    notifyListeners();
  }
}
