import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/util/image_compression.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
// Import the helper

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
    List<File>? additionalFiles,
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
      debugPrint('📦 Compressing images before upload...');

      // Compress all images before upload
      final compressedCustomerStart =
          await ImageCompressionHelper.compressMultipleImages(
            customerStartMeterFiles,
          );
      final compressedCustomerEnd =
          await ImageCompressionHelper.compressMultipleImages(
            customerEndMeterFiles,
          );
      final compressedVehicleStart =
          await ImageCompressionHelper.compressMultipleImages(
            vehicleStartMeterFiles,
          );
      final compressedVehicleEnd =
          await ImageCompressionHelper.compressMultipleImages(
            vehicleEndMeterFiles,
          );
      final compressedAdditional =
          additionalFiles != null
              ? await ImageCompressionHelper.compressMultipleImages(
                additionalFiles,
              )
              : <File>[];

      debugPrint('✅ Image compression completed');

      // Prepare multipart files with compressed images
      Future<List<MultipartFile>> prepareFiles(List<File> files) async {
        if (files.isEmpty) return [];
        return await Future.wait(
          files.map((file) async {
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            );
            debugPrint(
              '📁 File: ${file.path.split('/').last}, Size: ${await file.length()} bytes',
            );
            return multipartFile;
          }),
        );
      }

      final customerStartFiles = await prepareFiles(compressedCustomerStart);
      final customerEndFiles = await prepareFiles(compressedCustomerEnd);
      final vehicleStartFiles = await prepareFiles(compressedVehicleStart);
      final vehicleEndFiles = await prepareFiles(compressedVehicleEnd);
      final additionalMultipartFiles = await prepareFiles(compressedAdditional);

      debugPrint(
        '📁 Prepared ${customerStartFiles.length} customer start photos',
      );
      debugPrint('📁 Prepared ${customerEndFiles.length} customer end photos');
      debugPrint(
        '📁 Prepared ${vehicleStartFiles.length} vehicle start photos',
      );
      debugPrint('📁 Prepared ${vehicleEndFiles.length} vehicle end photos');
      debugPrint(
        '📁 Prepared ${additionalMultipartFiles.length} additional photos',
      );

      // Create Dio with proper timeout configuration
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      // Add logging interceptor
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: true, error: true),
      );

      debugPrint('🌐 Sending API request...');

      final response = await RestClient(dio).postFuelVehicleWithMeterReading(
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
        customerStartMeterReadingValue: customerStartMeterReadingValue,
        customerStartMeterFiles: customerStartFiles,
        customerEndMeterReadingValue: customerEndMeterReadingValue,
        customerEndMeterFiles: customerEndFiles,
        additionalFiles: additionalMultipartFiles,
      );

      debugPrint('✅ API Response received');

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
