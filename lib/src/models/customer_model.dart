import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_model.freezed.dart';
part 'customer_model.g.dart';

@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    int? id,
    String? Name,
    String? mobile,
    String? representative,
    String? email,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
