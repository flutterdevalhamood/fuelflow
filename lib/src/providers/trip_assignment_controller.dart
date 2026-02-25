import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/models/customer_site_model.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/models/trip_detail_model.dart';
import 'package:sample/src/models/trip_stop_model.dart';
import 'package:sample/src/repo/auth_repo.dart';

class TripController with ChangeNotifier {
  List<Trip> trips = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  String? error;
  String filterStatus = 'all';
  String searchQuery = '';
  final token = AuthRepo.token;
  final int _pageSize = 10;

  bool isCreating = false;
  String? createError;

  List<TripCustomer> customers = [];
  bool isLoadingCustomers = false;

  List<CustomerSite> customerSites = [];
  bool isLoadingSites = false;

  bool isSavingStops = false;
  String? saveStopsError;

  List<TripStop> tripStops = [];
  bool isLoadingStops = false;

  bool isSavingVehicles = false;
  String? saveVehiclesError;

  List<dynamic> availableDrivers = [];
  List<dynamic> availableVehicles = [];
  bool isLoadingAssignmentOptions = false;
  bool isSavingAssignment = false;
  String? saveAssignmentError;

  bool isUpdatingTrip = false;
  String? updateTripError;

  TripDetail? tripDetail;
  bool isTripDetailLoading = false;
  String? tripDetailError;

  // Replace with your actual RestClient call
  Future<void> fetchTrips({bool loadMore = false}) async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    if (!loadMore) {
      currentPage = 1;
      trips = [];
    }
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final trip = await restApi.getTrips(
        'Bearer $token',
        currentPage,
        _pageSize,
      );

      if (trip['IsSuccess'] == true) {
        final data =
            (trip['Data'] as List)
                .map((e) => Trip.fromJson(e as Map<String, dynamic>))
                .toList();

        if (loadMore) {
          trips.addAll(data);
        } else {
          trips = data;
        }
        hasMore = data.length == _pageSize;
        currentPage++;
      } else {
        error = trip['Message'] as String? ?? 'Something went wrong';
      }
    } catch (e) {
      error = 'Failed to load trips. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Trip> get filteredTrips {
    return trips.where((t) {
      final matchStatus = filterStatus == 'all' || t.status == filterStatus;
      final matchSearch =
          searchQuery.isEmpty ||
          t.customer.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.id.toString().contains(searchQuery);
      return matchStatus && matchSearch;
    }).toList();
  }

  void setFilter(String status) {
    filterStatus = status;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      fetchTrips(loadMore: true);
    }
  }

  Future<bool> createTrip({
    required String customerId,
    required String scheduledStart,
    required String scheduledEnd,
    String? notes,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.postRegisterTrip(
        token: 'Bearer $token',
        customerId: customerId,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        // notes field in REST client is int? — pass null or convert as needed
        // If your API accepts a string, update the @Field type to String?
        notes: null,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        // Refresh list so new trip appears at top
        await fetchTrips();
        return true;
      } else {
        createError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to create trip';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        createError =
            e.response?.data?['Message'] as String? ??
            'Network error. Please try again.';
      } else {
        createError = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripBaseList() async {
    isLoadingCustomers = true;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.getTripBaseList('Bearer $token');

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as Map<String, dynamic>;
        final list = data['customers'] as List<dynamic>;
        customers =
            list
                .map((e) => TripCustomer.fromJson(e as Map<String, dynamic>))
                .toList();
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception fetching base list: $e');
      }
    } finally {
      isLoadingCustomers = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomerSites(int customerId) async {
    isLoadingSites = true;
    customerSites = [];
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.getCustomerSites(
        'Bearer $token',
        customerId,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as Map<String, dynamic>;
        final list = data['sites'] as List<dynamic>;
        customerSites =
            list
                .map((e) => CustomerSite.fromJson(e as Map<String, dynamic>))
                .toList();
      }
    } catch (e) {
      if (e is DioException) print('Dio error fetching sites: $e');
    } finally {
      isLoadingSites = false;
      notifyListeners();
    }
  }

  Future<bool> saveStops({
    required int tripId,
    required List<Map<String, dynamic>> stops,
  }) async {
    isSavingStops = true;
    saveStopsError = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.postAddTripStops('Bearer $token', tripId, {
        'stops': stops,
      });

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        return true;
      } else {
        saveStopsError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to save stops';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        saveStopsError =
            e.response?.data?['Message'] as String? ??
            'Network error. Please try again.';
      } else {
        saveStopsError = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      isSavingStops = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripStops(int tripId) async {
    isLoadingStops = true;
    tripStops = [];
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.getTripStops('Bearer $token', tripId);

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as Map<String, dynamic>;
        final list = data['stops'] as List<dynamic>;
        tripStops =
            list
                .map((e) => TripStop.fromJson(e as Map<String, dynamic>))
                .toList();
      }
    } catch (e) {
      if (e is DioException) print('Dio error fetching trip stops: $e');
    } finally {
      isLoadingStops = false;
      notifyListeners();
    }
  }

  Future<bool> saveTripStopVehicles({
    required int stopId,
    required List<int> vehicleIds,
  }) async {
    isSavingVehicles = true;
    saveVehiclesError = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.postSaveTripStopVehicles(
        'Bearer $token',
        stopId, // ← direct parameter
        vehicleIds, // ← direct list parameter
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        return true;
      } else {
        saveVehiclesError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to save vehicles';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        saveVehiclesError =
            e.response?.data?['Message'] as String? ??
            'Network error. Please try again.';
      } else {
        saveVehiclesError = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      isSavingVehicles = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripAssignmentOptions(int tripId) async {
    isLoadingAssignmentOptions = true;
    availableDrivers = [];
    availableVehicles = [];
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");
      final response = await restApi.getTripAssignmentOptions(
        'Bearer $token',
        tripId,
      );
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as Map<String, dynamic>;
        availableDrivers = data['availableDrivers'] as List<dynamic>;
        availableVehicles = data['availableVehicles'] as List<dynamic>;
      }
    } catch (e) {
      if (e is DioException) print('Dio error fetching assignment options: $e');
    } finally {
      isLoadingAssignmentOptions = false;
      notifyListeners();
    }
  }

  Future<bool> saveTripAssignment({
    required int tripId,
    required int vehicleId,
    required int driverId,
  }) async {
    isSavingAssignment = true;
    saveAssignmentError = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");
      final response = await restApi.postSaveTripAssignments(
        tripId: tripId,
        token: 'Bearer $token',
        stopId: vehicleId,
        vehicles: driverId,
      );
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        return true;
      } else {
        saveAssignmentError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to save assignment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        saveAssignmentError =
            e.response?.data?['Message'] as String? ?? 'Network error.';
      } else {
        saveAssignmentError = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      isSavingAssignment = false;
      notifyListeners();
    }
  }

  Future<bool> updateTrip({
    required int tripId,
    required String customerId,
    required String scheduledStart,
    required String scheduledEnd,
    String? notes,
  }) async {
    isUpdatingTrip = true;
    updateTripError = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.putUpdateTrip(
        tripId: tripId,
        token: 'Bearer $token',
        body: {
          'customer_id': customerId,
          'scheduled_start': scheduledStart,
          'scheduled_end': scheduledEnd,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        await fetchTrips();
        return true;
      } else {
        updateTripError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to update trip';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        updateTripError =
            e.response?.data?['Message'] as String? ??
            'Network error. Please try again.';
      } else {
        updateTripError = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      isUpdatingTrip = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripDetail(int tripId) async {
    isTripDetailLoading = true;
    tripDetailError = null;
    tripDetail = null;
    notifyListeners();

    try {
      if (token == null) throw Exception("No Token Found");

      final response = await restApi.getTripDetails('Bearer $token', tripId);

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        tripDetail = TripDetail.fromJson(
          response['Data'] as Map<String, dynamic>,
        );
      } else {
        tripDetailError =
            (response is Map ? response['Message'] as String? : null) ??
            'Failed to load trip details';
      }
    } catch (e) {
      tripDetailError = 'Failed to load trip details. Please try again.';
    } finally {
      isTripDetailLoading = false;
      notifyListeners();
    }
  }
}
