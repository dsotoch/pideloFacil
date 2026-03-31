import 'package:dio/dio.dart';
import 'package:pidelofacil_moto/core/env.dart';

import 'funciones.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "${Env.dominio}/api",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) {
        return status! < 500;
      },

      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    ),
  );

  static void init() {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await Funciones().getToken();
          if (token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }
}
