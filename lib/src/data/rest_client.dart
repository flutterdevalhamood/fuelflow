import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sample/src/constants/api_constants.dart';
import 'package:sample/src/models/user_model.dart';

part 'rest_client.g.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiEndPoint,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false, // ✅ ADD THIS
      validateStatus: (status) {
        // ✅ ADD THIS - Treat both 200-299 and 302 as valid
        return status != null && status >= 200 && status < 400;
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
    ),
  );

  return dio;
}

Dio createDioWithLogging() {
  var dio = createDio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
        print('📋 Headers: ${options.headers}');
        print('📦 Data: ${options.data}');
        print('🔍 Query Parameters: ${options.queryParameters}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE[${response.statusCode}]');
        print('📥 Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ ERROR[${e.response?.statusCode}]');
        print('📛 Message: ${e.message}');
        print('📛 Response: ${e.response?.data}');
        return handler.next(e);
      },
    ),
  );

  // Add the standard logging interceptor
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) => print(obj),
    ),
  );

  return dio;
}

var dio = createDioWithLogging();
var restApi = RestClient(dio, baseUrl: apiEndPoint);

@RestApi(baseUrl: apiEndPoint)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST('/Login')
  @FormUrlEncoded()
  Future<UserModel> login({
    @Field("email") String? email,
    @Field("password") String? password,
    @Field("device_token") String? deviceToken,
  });

  @POST('/Logout')
  @FormUrlEncoded()
  Future<dynamic> logout({
    @Header("Authorization") String? token,
    @Field("id") String? id,
    @Field("device_token") String? deviceToken,
  });

  @GET('/Vehicle/paginate/{page}/{limit}')
  Future<dynamic> getVehicleData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @GET('/getVehicleBaseList')
  Future<dynamic> getVehicleDropDownData(
    @Header("Authorization") String? token,
  );

  @POST('/Vehicle')
  Future<dynamic> registerVehicle({
    @Header("Authorization") String? token,
    @Field("plate_no") String? platNumber,
    @Field("capacity") String? capacity,
    @Field("description") String? description,
    @Field("vehicle_type_id") int? vehicleTypeId,
    @Field("capacity_unit_id") int? capacityUnitId,
    @Field("customer_id") int? customerId,
    @Field("customer_id") int? customerSiteId,
  });

  @POST('/VehicleUpdate')
  Future<dynamic> editVehicleData({
    @Header("Authorization") String? token,
    @Field("plate_no") String? plate_no,
    @Field("vehicle_type_id") int? vehicle_type_id,
    @Field("id") int? id,
    @Field("description") String? description,
    @Field("capacity") String? capacity,
    @Field("vehicle_type_id") int? capacity_unit_id,
    @Field("customer_id") int? customerId,
  });

  @POST('/VehicleDelete')
  Future<dynamic> deleteVehicle({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/Customer/paginate/{page}/{limit}')
  Future<dynamic> getCustomerList(
    @Header("Authorization") String? token,
    @Path("page") int? page,
    @Path("limit") int? limit,
  );

  @POST('/Customer')
  Future<dynamic> registerCustomer({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
    @Field("representative") String? representative,
    @Field("mobile") String? mobile,
    @Field("secondary_mobile") String? secondaryMobile,
    @Field("email") String? email,
    @Field("is_admin") int? isAdmin,
  });

  @POST('/CustomerDelete')
  Future<dynamic> deleteCustomer({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @POST('/CustomerUpdate')
  Future<dynamic> updateCustomer({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("Name") String? name,
    @Field("representative") String? representative,
    @Field("mobile") String? mobile,
    @Field("email") String? email,
  });

  @POST('/VehiclePictureUpload')
  @MultiPart()
  Future<dynamic> uploadVehiclePictures({
    @Header("Authorization") String? token,
    @Part(name: 'document[]') List<MultipartFile>? files,
    @Part(name: 'id') String? id,
  });

  @POST('/VehiclePictureDeleteByID')
  Future<dynamic> deleteImagesById({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });

  @GET('/getCustomerSites/{customerId}')
  Future<dynamic> getCustomerSitesOfCustomer({
    @Path("customerId") int? customerId,
    @Header("Authorization") String? token,
  });

  @GET('/Driver/paginate/{page}/{limit}')
  Future<dynamic> getDriverData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/Driver')
  Future<dynamic> registerDriver({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
    @Field("Mobile") String? mobile,
    @Field("customer_id") int? customerId,
  });

  @POST('/DriverUpdate')
  Future<dynamic> updateDriver({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("Name") String? name,
    @Field("Mobile") String? mobile,
  });

  @POST('/DriverDelete')
  Future<dynamic> deleteDriver({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/Product/paginate/{page}/{limit}')
  Future<dynamic> getProductData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/Product')
  Future<dynamic> registerProduct({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
  });

  @POST('/ProductUpdate')
  Future<dynamic> updateProduct({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("Name") String? name,
  });

  @POST('/ProductDelete')
  Future<dynamic> deleteProduct({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/CustomerSite/paginate/{page}/{limit}')
  Future<dynamic> getCustomerSite(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/CustomerSite')
  Future<dynamic> postCustomerSite({
    @Header("Authorization") String? token,
    @Field("customer_id") int? customerId,
    @Field("name") String? name,
    @Field("description") String? description,
  });

  @POST('/CustomerSiteUpdate')
  Future<dynamic> updateCustomerSite({
    @Header("Authorization") String? token,
    @Field("customer_id") int? customerId,
    @Field("name") String? name,
    @Field("description") String? description,
    @Field("id") int? id,
  });

  @POST('/CustomerSiteDelete')
  Future<dynamic> deleteCustomerSite({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/getDriverBaseList')
  Future<dynamic> getCustomerDropDown(@Header("Authorization") String? token);

  @GET('/getRefilBaseList')
  Future<dynamic> getRefillDropDown(@Header("Authorization") String? token);

  @POST('/getDriverVehicleOfCustomer')
  Future<dynamic> getDriverVehicleOfCustomer({
    @Header("Authorization") String? token,
    @Field("customer_id") int? customerId,
  });

  @GET('/Refil/paginate/{page}/{limit}')
  Future<dynamic> getRefilData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/Refil')
  @MultiPart()
  Future<dynamic> postRefilData({
    @Header("Authorization") String? token,
    @Part(name: "qty") String? quantity,
    @Part(name: "customer_id") int? customerId,
    @Part(name: "unit_id") int? unitId,
    @Part(name: "product_id") int? productId,
    @Part(name: "driver_id") int? driverId,
    @Part(name: "vehicle_id") int? vehicleId,
    @Part(name: "refiling_unit_id") int? refillingUnitId,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @POST('/RefilUpdate')
  Future<dynamic> refillUpdate({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("qty") String? qty,
    @Field("driver_id") int? driverId,
  });

  @POST('/RefilDelete')
  Future<dynamic> refillDelete({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @POST('/RefilPictureUpload')
  @MultiPart()
  Future<dynamic> uploadRefillImages({
    @Header("Authorization") String? token,
    @Part(name: 'document[]') List<MultipartFile>? files,
    @Part(name: 'id') String? id,
  });

  @POST('/RefilingUnitPictureUpload')
  @MultiPart()
  Future<dynamic> uploadRefillingUnitImages({
    @Header("Authorization") String? token,
    @Part(name: 'document[]') List<MultipartFile>? files,
    @Part(name: 'id') String? id,
  });

  @GET('/RefilingUnit/paginate/{page}/{limit}')
  Future<dynamic> getRefilingUnitData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/RefilingUnit')
  Future<dynamic> postRefillingUnit({
    @Header("Authorization") String? token,
    @Part(name: "type") int? type,
    @Part(name: "serial_no") String? serialNumber,
    @Part(name: "vehicle_id") int? vehicleId,
    @Part(name: "driver_id") int? driverId,
    @Part(name: "capacity") String? capacity,
    @Part(name: "capacity_unit_id") int? capacityUnitId,
    @Part(name: "default_product_id") int? defaultProductId,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @POST('/RefilingUnitPictureUpload')
  @MultiPart()
  Future<dynamic> uploadrefillingUnitPictures({
    @Header("Authorization") String? token,
    @Part(name: 'document[]') List<MultipartFile>? files,
    @Part(name: 'id') String? id,
  });

  @POST('/RefilingUnitUpdate')
  Future<dynamic> refillingUnitUpdate({
    @Header("Authorization") String? token,
    @Field("type") int? type,
    @Field("serial_no") String? serialNumber,
    @Field("vehicle_id") int? vehicleId,
    @Field("driver_id") int? driverId,
    @Field("capacity") String? capacity,
    @Field("capacity_unit_id") int? capacityUnitId,
    @Field("default_product_id") int? defaultProductId,
    @Field("id") int? id,
  });

  @GET('/getRefilingUnitBaseList')
  Future<dynamic> refillingUnitBaseList({
    @Header("Authorization") String? token,
  });

  @POST('/getDefaultsOfRefilingUnit')
  Future<dynamic> getDefaultsOfRefilingUnit({
    @Header("Authorization") String? token,
    @Field("refiling_unit_id") int? refillingUnitId,
  });

  @POST('/RefilingUnitDelete')
  Future<dynamic> deleteRefillingUnit({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @POST('/RefilingUnitPictureDeleteByID')
  Future<dynamic> deleteRefillingUnitImagesById({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });

  @POST('/RefilReport')
  Future<dynamic> postReportsData({
    @Header("Authorization") String? token,
    @Field("fromDate") String? fromDate,
    @Field("toDate") String? toDate,
    @Field("customer_id") String? customerId,
  });

  @POST('/ActivityReport')
  Future<dynamic> postActivityReportsData({
    @Header("Authorization") String? token,
    @Field("fromDate") String? fromDate,
    @Field("toDate") String? toDate,
    @Field("action") String? action,
  });

  @POST('/InventoryReport')
  Future<dynamic> postInventoryReportsData({
    @Header("Authorization") String? token,
    @Field("fromDate") String? fromDate,
    @Field("toDate") String? toDate,
    @Field("refiling_unit_id") int? refillingUnitId,
  });

  @GET('/getRefilingUnitSerialNo')
  Future<dynamic> refillingUnitSerialNumber({
    @Header("Authorization") String? token,
  });

  @POST('/SaveAssignedRefilingUnit')
  Future<dynamic> assignRefillingUnit({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("customer_id") int? customerId,
  });

  @POST('/ReleaseRefilingUnit')
  Future<dynamic> releaseRefillingUnit({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("releaseDescription") String? releaseDescription,
  });

  @GET('/StorageRefil/paginate/{page}/{limit}')
  Future<dynamic> getStorageUnitData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/StorageRefil')
  Future<dynamic> postStorageUnitData({
    @Header("Authorization") String? token,
    @Part(name: "refiling_unit_id") int? id,
    @Part(name: "driver_id") int? driverId,
    @Part(name: "vehicle_id") int? vehicleId,
    @Part(name: "product_id") int? productId,
    @Part(name: "qty") int? qty,
    @Part(name: "unit_id") int? unitId,
    @Part(name: "description") String? description,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @GET('/RefilingUnitByCustomer/{customerId}')
  Future<dynamic> getAssignedUnitForCustomer({
    @Path("customerId") int? customerId,
    @Header("Authorization") String? token,
  });

  @GET('/ToggleDriverStatus/{id}')
  Future<dynamic> toggleDriverStatus({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @GET('/ToggleVehicleStatus/{id}')
  Future<dynamic> toggleVehicleStatus({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/SuperAdminCreateDriver')
  Future<dynamic> superAdminCreateDriver({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
    @Field("Mobile") String? mobile,
    @Field("customer_id") int? customerId,
  });

  @POST('/SuperAdminCreateVehicle')
  Future<dynamic> superAdminCreateVehicle({
    @Header("Authorization") String? token,
    @Field("plate_no") String? platNumber,
    @Field("vehicle_type_id") int? vehicleTypeId,
    @Field("capacity") String? capacity,
    @Field("description") String? description,
    @Field("capacity_unit_id") int? capacityUnitId,
    @Field("customer_id") int? customerId,
    @Field("customer_site_id") int? customerSiteId,
  });

  @GET('/Driver/GetAssignedTrips/{page}/{limit}')
  Future<dynamic> getAssignedTrips(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/Driver/SubmitDriverResponse')
  @FormUrlEncoded()
  Future<dynamic> postSubmitDriverResponse({
    @Header("Authorization") String? token,
    @Field("assignment_id") int? assignmentId,
    @Field("driver_id") int? driverId,
    @Field("response") String? response,
    @Field("reason") String? reason,
  });

  @GET('/Driver/GetAcceptedAssignments/{page}/{limit}')
  Future<dynamic> getAcceptedAssignments(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @GET('/Driver/GetCompletedAssignments/{page}/{limit}')
  Future<dynamic> getCompletedAssignments(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/Driver/FuelVehicle')
  Future<dynamic> postFuelVehicle({
    @Header("Authorization") String? token,
    @Field("vehicle_id") int? vehicleId,
    @Field("trip_id") String? tripId,
    @Field("trip_stop_id") int? tripStopId,
    @Field("type") String? inFlow,
    @Field("quantity") String? quantity,
    @Field("before_quantity") String? beforeQuantity,
    @Field("after_quantity") String? afterQuantity,
    @Field("note") String? note,
  });

  @POST('/Driver/StoreMeterReadingEvent')
  @MultiPart()
  Future<dynamic> postStoreMeterReading({
    @Header("Authorization") String? token,
    @Part(name: "stock_event_id") int? stockEventId,
    @Part(name: "reading_type") String? readingType,
    @Part(name: "trip_stop_id") int? tripStopId,
    @Part(name: "vehicle_id") int? vehicleId,
    @Part(name: "reading_value") String? readingValue,
    @Part(name: "note") String? note,
    @Part(name: 'photo_path') List<MultipartFile>? files,
  });

  @POST('/Driver/FuelVehicleWithMeterReading')
  @MultiPart()
  Future<dynamic> postFuelVehicleWithMeterReading({
    @Header("Authorization") String? token,
    @Part(name: "vehicle_id") int? vehicleId,
    @Part(name: "type") String? inFlow,
    @Part(name: "quantity") String? quantity,
    @Part(name: "before_quantity") String? beforeQuantity,
    @Part(name: "after_quantity") String? afterQuantity,
    @Part(name: "note") String? note,
    @Part(name: "trip_id") String? tripId,
    @Part(name: "trip_stop_id") int? tripStopId,
    @Part(name: "vehicle_tank_start_reading_value")
    int? vehicleTankStartReadingValue,
    @Part(name: "vehicle_tank_start")
    List<MultipartFile>? vehicleStartMeterFiles,
    @Part(name: "vehicle_tank_end_reading_value")
    int? vehicleTankEndReadingValue,
    @Part(name: "vehicle_tank_end") List<MultipartFile>? vehicleEndMeterFiles,
    @Part(name: "customer_start_meter_reading_value")
    int? customerStartMeterReadingValue,
    @Part(name: "customer_start_meter")
    List<MultipartFile>? customerStartMeterFiles,
    @Part(name: 'customer_end_meter_reading_value')
    int? customerEndMeterReadingValue,
    @Part(name: 'customer_end_meter')
    List<MultipartFile>? customerEndMeterFiles,
    @Part(name: 'files') List<MultipartFile>? additionalFiles,
    @Part(name: "stop_vehicle_id") String? stopVehicleId,
  });

  @GET('/Driver/GetTripEvents')
  Future<dynamic> getDriverTripEvents({@Header("Authorization") String? token});

  @POST('/Driver/LogTripEvent/{tripId}')
  @FormUrlEncoded()
  Future<dynamic> postLogTripEvent({
    @Path("tripId") int? tripId,
    @Header("Authorization") String? token,
    @Field("trip_stop_id") int? tripStopId,
    @Field("event_type") String? eventType,
    @Field("description") String? description,
    @Field("latitude") String? latitude,
    @Field("longitude") String? longitude,
  });

  @POST('/Driver/LogTripLocations/{tripId}')
  @FormUrlEncoded()
  Future<dynamic> postLogTripLocations({
    @Path("tripId") int? tripId,
    @Header("Authorization") String? token,
    @Field("driver_id") int? driverId,
    @Field("vehicle_id") int? vehicleId,
    @Field("latitude") String? latitude,
    @Field("longitude") String? longitude,
  });

  @GET('/getUserBaseList')
  Future<dynamic> getUsersBaseList({@Header("Authorization") String? token});

  @GET('/AllUsers/{page}/{limit}')
  Future<dynamic> getAllUsers(
    @Header("Authorization") String? token,
    @Path("page") int page,
    @Path("limit") int limit,
  );

  @POST('/userRegistration')
  Future<dynamic> postUserRegistration({
    @Header("Authorization") String? token,
    @Field("name") String? name,
    @Field("email") String? email,
    @Field("password") String? password,
    @Field("role_id") int? roleId,
    @Field("driver_id") int? driverId,
    @Field("customer_id") int? customerId,
  });

  @POST('/Driver/IgnoreFuelRefillForTripStopVehicle')
  Future<dynamic> postVehicleNotAvailable({
    @Header("Authorization") String? token,
    @Field("vehicle_id") List<int>? vehicleId,
    @Field("description") String? description,
    @Field("trip_stop_id") int? tripStopId,
  });

  @POST('/Driver/GetRefillingStatusForStop')
  Future<dynamic> getRefillingStatusForStop({
    @Header("Authorization") String? token,
    @Field("trip_id") String? tripId,
    @Field("trip_stop_id") int? tripStopId,
  });

  @POST('/Driver/RequestAdminVehicleRefilingForShortage')
  @FormUrlEncoded()
  Future<dynamic> requestAdminVehicleRefilingForShortage({
    @Header("Authorization") String? token,
    @Field("latitude") String? latitude,
    @Field("longitude") String? longitude,
    @Field("expected_quantity") String? expectedQuantity,
    @Field("notes") String? notes,
    @Field("vehicle_id") String? vehicleId,
  });
}
