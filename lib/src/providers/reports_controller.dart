import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class ReportsController with ChangeNotifier {
  final token = AuthRepo.token;
  String? reportUrl;
  String? activityReportUrl;

  Future<bool> postReportsData(
    String? fromDate,
    String? toDate,
    String? customerId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final reportsData = await restApi.postReportsData(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        customerId: customerId,
      );
      if (reportsData['IsSuccess'] == true) {
        reportUrl = reportsData['Data']?['url'];
        notifyListeners();
        print('reportsurlll $reportUrl');
        return true;
      } else {
        print('Fetch reports data failed: ${reportsData['Message']}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> postActivityReportsData(
    String? fromDate,
    String? toDate,
    String? action,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final activityReportsData = await restApi.postActivityReportsData(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        action: action,
      );
      if (activityReportsData['IsSuccess'] == true) {
        activityReportUrl = activityReportsData['Data']?['url'];
        notifyListeners();
        print('activityReportUrl $activityReportUrl');
        return true;
      } else {
        print('Fetch reports data failed: ${activityReportsData['Message']}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }
}
