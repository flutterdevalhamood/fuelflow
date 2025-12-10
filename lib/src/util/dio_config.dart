import 'package:dio/dio.dart';

Dio createDio() {
  final dio = Dio();

  dio.options = BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: {"Accept": "application/json"},
  );

  // Optional interceptor:
  // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
}
