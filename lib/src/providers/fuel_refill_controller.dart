import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelRefillController with ChangeNotifier {
  List<Map<String, dynamic>>? unitData;
  List<Map<String, dynamic>>? productData;
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? driverData;
  List<Map<String, dynamic>>? vehicleData;

  final token = AuthRepo.token;

  Future<void> getFuelRefillDropdown() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final dropDownData = await restApi.getRefillDropDown('Bearer $token');
      if (dropDownData['IsSuccess'] == true) {
        unitData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['unit'],
        );
        productData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['product'],
        );
        customerData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['customer'],
        );
        notifyListeners();
      } else {
        print('API call failed: ${dropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }

  Future<void> getDriverVehicleDropdown(int? customerId) async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final driverVehicleDropDownData = await restApi
          .getDriverVehicleOfCustomer(
            token: 'Bearer $token',
            customerId: customerId,
          );
      if (driverVehicleDropDownData['IsSuccess'] == true) {
        driverData = List<Map<String, dynamic>>.from(
          driverVehicleDropDownData['Data']['driver'],
        );
        vehicleData = List<Map<String, dynamic>>.from(
          driverVehicleDropDownData['Data']['vehicle'],
        );
        notifyListeners();
      } else {
        print('API call failed: ${driverVehicleDropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }
}
