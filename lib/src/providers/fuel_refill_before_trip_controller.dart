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
    required String type, // 'inflow' or 'outflow'
    required num quantity, // Refill quantity
    required num beforeQuantity, // Quantity already in tank
    required num afterQuantity, // Quantity after refilling
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
