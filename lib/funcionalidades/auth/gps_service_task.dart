import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/gps_service.dart';

class GpsService extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;
  StreamSubscription<LocationServicesStatus>?
  _locationServicesStatusSubscription;

  String? user_id;
  Location? _ultimaUbicacion;

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _locationServicesStatusSubscription?.cancel();
    _locationServicesStatusSubscription = null;
    if (kDebugMode) {
      print("☑️ SERVICIO DETENIDO");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("✅ SERVICIO INICIADO");
    _streamSubscription = FlLocation.getLocationStream().listen((
      location,
    ) async {
      if (_ultimaUbicacion == null ||
          calcularDistancia(_ultimaUbicacion!, location) > 10) {
        _ultimaUbicacion = location;
        final String message = '${location.latitude}, ${location.longitude}';
        FlutterForegroundTask.updateService(notificationText: message);

        if (user_id != null) {
          try {
            await ServiceGps().guardarPosicion(
              user_id!,
              location.latitude.toString(),
              location.longitude.toString(),
            );
          } catch (e) {
            if (e is DioException) {
              if (kDebugMode) {
                print("📡 STATUS: ${e.response?.statusCode}");
                print("📡 DATA: ${e.response?.data}");
              }
            }
          }
        }
      }
    });
    _locationServicesStatusSubscription =
        FlLocation.getLocationServicesStatusStream().listen(
          _onLocationServicesStatus,
        );
  }

  void _onLocationServicesStatus(LocationServicesStatus status) {
    FlutterForegroundTask.sendDataToMain({
      "type": "gps_status",
      "status": status.name,
    });
  }

  double calcularDistancia(Location a, Location b) {
    const R = 6371000;
    double dLat = (b.latitude - a.latitude) * pi / 180;
    double dLon = (b.longitude - a.longitude) * pi / 180;

    double lat1 = a.latitude * pi / 180;
    double lat2 = b.latitude * pi / 180;

    double aHarv =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(aHarv), sqrt(1 - aHarv));

    return R * c;
  }

  @override
  void onReceiveData(Object data) {
    super.onReceiveData(data); // siempre primero llamar al super

    try {
      Map<String, dynamic> mapData;

      if (data is String) {
        mapData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        mapData = data;
      } else {
        throw Exception("Tipo de dato inesperado en onReceiveData");
      }

      user_id = mapData["user_id"]?.toString();
    } catch (e) {
      if (kDebugMode) print("❌ Error al recibir datos: $e");
    }
  }
}
