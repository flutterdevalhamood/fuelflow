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
  Future<dynamic> postRefilData({
    @Header("Authorization") String? token,
    @Field("qty") String? quantity,
    @Field("customer_id") int? customerId,
    @Field("unit_id") int? unitId,
    @Field("product_id") int? productId,
    @Field("driver_id") int? driverId,
    @Field("vehicle_id") int? vehicleId,
    @Field("refiling_unit_id") int? refillingUnitId,
  });

  @POST('/RefilUpdate')
  Future<dynamic> refillUpdate({
    @Header("Authorization") String? token,
    @Field("plate_no") String? plateNumber,
    @Field("vehicle_type_id") int? vehicleType,
    @Field("id") int? id,
    @Field("description") String? description,
    @Field("capacity") String? capacity,
    @Field("capacity_unit_id") String? capacityUnit,
    @Field("customer_id") String? customer,
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
}
