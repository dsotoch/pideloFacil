import 'package:dio/dio.dart';

import '../../core/dio_client.dart';

class AuthService {
  Future<Response> login(
    String email,
    String password,
    String deviceUUID,
    String modelo,
    String plataforma,
  ) {
    return DioClient.dio.post(
      "/login",
      data: {
        "email": email,
        "password": password,
        "uuid": deviceUUID,
        "modelo": modelo,
        "plataforma": plataforma,
      },
      options: Options(headers: {'Device-UUID': deviceUUID}),
    );
  }

  Future<Response> saveToken(String token, String user_id) {
    return DioClient.dio.post(
      "/save-token",
      data: {"device_token": token, "user_id": user_id},
    );
  }

  Future<Response> logout(String uuid,String user_id) {
    return DioClient.dio.post("/logout",
      data: {"uuid": uuid, "user_id": user_id},
    );
  }
}
