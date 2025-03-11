import 'package:freezed_annotation/freezed_annotation.dart';

import 'customer_model.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

@freezed
abstract class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    int? StatusCode,
    String? Message,
    bool? IsSuccess,
    List<Customer>? Data,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}
