import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sample/src/constants/api_constants.dart';
import 'package:sample/src/models/user_model.dart';

part 'rest_client.g.dart';

var dio = Dio();
var restApi = RestClient(dio, baseUrl: apiEndPoint);

@RestApi(baseUrl: apiEndPoint)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST('/Login')
  Future<UserModel> login({
    @Field("email") String? email,
    @Field("password") String? password,
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
}
