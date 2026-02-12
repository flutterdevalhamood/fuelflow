import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/models/customer_view_my_refillings_model.dart';

import '../data/rest_client.dart';
import '../models/customer_view_vehicle_model.dart';
import '../repo/auth_repo.dart';

class CustomerViewController with ChangeNotifier {
  // Existing vehicle data
  List<CustomerViewVehicle>? customerViewVehiclesData;
  List<CustomerViewVehicle>? _allVehiclesData;
  bool isLoading = false;
  bool hasMore = false;
  int currentPage = 1;
  final int limit = 10;
  String? errorMessage;
  String _searchQuery = '';

  // Refilling data - now filtered only
  List<CustomerViewMyRefillingsModel>? refillingData;
  bool isLoadingRefillings = false;
  String? refillingErrorMessage;

  // Filter parameters
  DateTime? filterFromDate;
  DateTime? filterToDate;
  dynamic filterVehicleId; // Can be 'all' or List<int>
  List<int> selectedVehicleIds = [];
  bool isAllVehiclesSelected = true;

  // Search getter and setter for vehicles
  String get searchQuery => _searchQuery;

  bool isGeneratingPDF = false;
  String? pdfErrorMessage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterVehicles();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    customerViewVehiclesData = _allVehiclesData;
    notifyListeners();
  }

  // Filter vehicles based on search query
  void _filterVehicles() {
    if (_allVehiclesData == null) return;

    if (_searchQuery.isEmpty) {
      customerViewVehiclesData = _allVehiclesData;
    } else {
      customerViewVehiclesData =
          _allVehiclesData!
              .where(
                (vehicle) => vehicle.plateNo.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }
  }

  // Vehicle methods
  Future<void> getCustomerViewVehiclesData({bool loadMore = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      final token = AuthRepo.token;

      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      final customerViewVehicles = await restApi.getCustomerViewVehicles(
        token.startsWith('Bearer') ? token : 'Bearer $token',
        currentPage,
        limit,
      );

      print('API Response: $customerViewVehicles');

      if (customerViewVehicles['IsSuccess'] == true) {
        final data = customerViewVehicles['Data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final newCustomerViewVehicles =
              data
                  .map(
                    (v) =>
                        CustomerViewVehicle.fromJson(v as Map<String, dynamic>),
                  )
                  .toList();
          print(
            'Successfully fetched ${newCustomerViewVehicles.length} vehicles',
          );

          if (loadMore) {
            _allVehiclesData ??= [];
            _allVehiclesData!.addAll(newCustomerViewVehicles);
          } else {
            _allVehiclesData = newCustomerViewVehicles;
          }

          _filterVehicles();
          hasMore = data.length == limit;
        } else {
          print('No vehicles data found in response');
          if (!loadMore) {
            _allVehiclesData = [];
            customerViewVehiclesData = [];
          }
          hasMore = false;
        }
      } else {
        print('API call failed: ${customerViewVehicles['Message']}');
        print('Status Code: ${customerViewVehicles['StatusCode']}');
        errorMessage =
            customerViewVehicles['Message'] ?? 'Failed to load vehicles';
        if (!loadMore) {
          _allVehiclesData = [];
          customerViewVehiclesData = [];
        }
        hasMore = false;
      }
    } catch (e) {
      print('Error in getCustomerViewVehiclesData: $e');
      if (e is DioException) {
        print('Dio Exception Details:');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Path: ${e.requestOptions.path}');
        print('Request Headers: ${e.requestOptions.headers}');
        errorMessage = e.response?.data['Message'] ?? 'Network error occurred';
      } else {
        errorMessage = e.toString();
      }

      if (!loadMore) {
        _allVehiclesData = [];
        customerViewVehiclesData = [];
      }
      hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getCustomerViewVehiclesData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    _searchQuery = '';
    await getCustomerViewVehiclesData(loadMore: false);
  }

  // New Filter Methods
  void setFilterDates(DateTime? fromDate, DateTime? toDate) {
    filterFromDate = fromDate;
    filterToDate = toDate;
    notifyListeners();
  }

  void setFilterVehicles({bool allVehicles = true, List<int>? vehicleIds}) {
    isAllVehiclesSelected = allVehicles;
    if (allVehicles) {
      filterVehicleId = 'all';
      selectedVehicleIds = [];
    } else {
      selectedVehicleIds = vehicleIds ?? [];
      filterVehicleId =
          selectedVehicleIds.isNotEmpty ? selectedVehicleIds : 'all';
      // If vehicleIds is provided but empty, keep isAllVehiclesSelected as false
      if (selectedVehicleIds.isEmpty && !allVehicles) {
        isAllVehiclesSelected = true;
        filterVehicleId = 'all';
      }
    }
    notifyListeners();
  }

  void toggleVehicleSelection(int vehicleId) {
    if (selectedVehicleIds.contains(vehicleId)) {
      selectedVehicleIds.remove(vehicleId);
    } else {
      selectedVehicleIds.add(vehicleId);
    }

    // Get total vehicle count
    final totalVehicles = customerViewVehiclesData?.length ?? 0;

    // Check if all vehicles are now selected
    if (selectedVehicleIds.length == totalVehicles && totalVehicles > 0) {
      // All vehicles selected
      isAllVehiclesSelected = true;
      filterVehicleId = 'all';
    } else if (selectedVehicleIds.isEmpty) {
      // No vehicles selected - default to all
      isAllVehiclesSelected = true;
      filterVehicleId = 'all';
    } else {
      // Some vehicles selected
      isAllVehiclesSelected = false;
      filterVehicleId = selectedVehicleIds;
    }

    notifyListeners();
  }

  void selectAllVehicles(List<int> allVehicleIds) {
    // When "All Vehicles" is clicked, we want to pass 'all' to API
    selectedVehicleIds = List.from(allVehicleIds);
    isAllVehiclesSelected = true; // CHANGED: Set to true for "All Vehicles"
    filterVehicleId = 'all'; // CHANGED: Set to 'all' string
    notifyListeners();
  }

  void clearVehicleSelection() {
    selectedVehicleIds.clear();
    isAllVehiclesSelected = true;
    filterVehicleId = 'all';
    notifyListeners();
  }

  Future<String?> generateFilteredRefillingsPDF() async {
    isGeneratingPDF = true;
    pdfErrorMessage = null;
    notifyListeners();

    try {
      final token = AuthRepo.token;

      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      // Validate that at least from date is selected
      if (filterFromDate == null) {
        throw Exception("Please select a from date");
      }

      // Format dates as strings
      final String fromDateStr =
          '${filterFromDate!.year}-${filterFromDate!.month.toString().padLeft(2, '0')}-${filterFromDate!.day.toString().padLeft(2, '0')}';

      String? toDateStr;
      if (filterToDate != null) {
        toDateStr =
            '${filterToDate!.year}-${filterToDate!.month.toString().padLeft(2, '0')}-${filterToDate!.day.toString().padLeft(2, '0')}';
      }

      // Prepare request body (same as filter)
      final Map<String, dynamic> requestBody = {'fromDate': fromDateStr};

      if (toDateStr != null) {
        requestBody['toDate'] = toDateStr;
      }

      if (isAllVehiclesSelected || selectedVehicleIds.isEmpty) {
        requestBody['vehicle_id'] = 'all';
      } else {
        requestBody['vehicle_id'] = selectedVehicleIds;
      }

      print('PDF Request Body: $requestBody');

      final response = await restApi.postGenerateFilteredRefillingsPDF(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        body: requestBody,
      );

      print('Generate PDF API Response: $response');

      if (response['IsSuccess'] == true) {
        final pdfUrl = response['url'] as String?;
        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          print('PDF generated successfully: $pdfUrl');
          return pdfUrl;
        } else {
          throw Exception('PDF URL not found in response');
        }
      } else {
        pdfErrorMessage = response['Message'] ?? 'Failed to generate PDF';
        return null;
      }
    } catch (e) {
      print('Error in generateFilteredRefillingsPDF: $e');
      if (e is DioException) {
        print('Dio Exception Details:');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        pdfErrorMessage =
            e.response?.data['Message'] ?? 'Network error occurred';
      } else {
        pdfErrorMessage = e.toString();
      }
      return null;
    } finally {
      isGeneratingPDF = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    filterFromDate = null;
    filterToDate = null;
    filterVehicleId = 'all';
    selectedVehicleIds = [];
    isAllVehiclesSelected = true;
    refillingData = null;
    notifyListeners();
  }

  // Filter Refillings API Call
  Future<void> filterMyRefillings() async {
    isLoadingRefillings = true;
    refillingErrorMessage = null;
    notifyListeners();

    try {
      final token = AuthRepo.token;

      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      // Validate that at least from date is selected
      if (filterFromDate == null) {
        throw Exception("Please select a from date");
      }

      // Format dates as strings (adjust format based on your API requirements)
      final String fromDateStr =
          '${filterFromDate!.year}-${filterFromDate!.month.toString().padLeft(2, '0')}-${filterFromDate!.day.toString().padLeft(2, '0')}';

      String? toDateStr;
      if (filterToDate != null) {
        toDateStr =
            '${filterToDate!.year}-${filterToDate!.month.toString().padLeft(2, '0')}-${filterToDate!.day.toString().padLeft(2, '0')}';
      }

      print('Filtering with:');
      print('From Date: $fromDateStr');
      print('To Date: $toDateStr');
      print('Is All Vehicles: $isAllVehiclesSelected');
      print('Selected Vehicle IDs: $selectedVehicleIds');

      // Prepare request body
      final Map<String, dynamic> requestBody = {'fromDate': fromDateStr};

      // Add ToDate if selected
      if (toDateStr != null) {
        requestBody['ToDate'] = toDateStr;
      }

      // Add vehicle_id based on selection
      if (isAllVehiclesSelected) {
        requestBody['vehicle_id'] = 'all'; // String 'all'
      } else if (selectedVehicleIds.isNotEmpty) {
        requestBody['vehicle_id'] = selectedVehicleIds; // Array [2, 3, 4]
      } else {
        // If no selection, default to 'all'
        requestBody['vehicle_id'] = 'all';
      }

      print('Request Body: $requestBody');

      final response = await restApi.postFilterMyRefillingsWithBody(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        body: requestBody,
      );

      print('Filter Refilling API Response: $response');

      if (response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          refillingData =
              data
                  .map(
                    (r) => CustomerViewMyRefillingsModel.fromJson(
                      r as Map<String, dynamic>,
                    ),
                  )
                  .toList();
          print('Successfully fetched ${refillingData!.length} refillings');
        } else {
          print('No refillings data found in response');
          refillingData = [];
        }
      } else {
        print('API call failed: ${response['Message']}');
        print('Status Code: ${response['StatusCode']}');
        refillingErrorMessage =
            response['Message'] ?? 'Failed to load refillings';
        refillingData = [];
      }
    } catch (e) {
      print('Error in filterMyRefillings: $e');
      if (e is DioException) {
        print('Dio Exception Details:');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Path: ${e.requestOptions.path}');
        print('Request Headers: ${e.requestOptions.headers}');
        refillingErrorMessage =
            e.response?.data['Message'] ?? 'Network error occurred';
      } else {
        refillingErrorMessage = e.toString();
      }
      refillingData = [];
    } finally {
      isLoadingRefillings = false;
      notifyListeners();
    }
  }
}
