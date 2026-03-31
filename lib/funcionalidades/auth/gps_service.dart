import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/models/notification_permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pidelofacil_moto/core/dio_client.dart';

import '../../main.dart';

class ServiceGps {
  static final ServiceGps _instance = ServiceGps._internal();

  ServiceGps._internal();

  factory ServiceGps() {
    return _instance;
  }

  Future<void> requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        // When you call this function, will be gone to the settings page.
        // So you need to explain to the user why set it.
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }
  Future<Response> guardarPosicion(String user_id,String latitud,String longitud)async{
    return DioClient.dio.post(
        "/save-position",
        data: {
          "latitud":latitud,
          "longitud":longitud,
          "id_personal":user_id
        }
    );
}

  void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'servicio_gps_pidelofacil',
        channelName: ' Service Notification PIDELO FACIL',
        channelDescription: 'Estamos Rastreando tu Recorrido...',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> checkAllPermissions() async {
    // 🔔 Notificaciones
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (notificationPermission != NotificationPermission.granted) {
      return false;
    }

    // 🤖 Solo Android
    if (Platform.isAndroid) {
      // 🔋 Batería (muy importante para que no maten tu servicio)
      final ignoreBattery =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;

      if (!ignoreBattery) {
        return false;
      }

      // ⏰ Alarmas exactas (opcional pero recomendado)
      final canSchedule = await FlutterForegroundTask.canScheduleExactAlarms;

      if (!canSchedule) {
        return false;
      }
    }
    var location = await Permission.location.request();

    if (location.isDenied) return false;

    // Android 10+
    var background = await Permission.locationAlways.request();

    return location.isGranted;
  }

  Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 500,
        notificationTitle: 'Rastreo Iniciado Correctamente',
        notificationText: 'Estamos Rastreando tu recorrido.',
        notificationIcon: null,
        serviceTypes: [ForegroundServiceTypes.location],
        callback: startCallback,
      );
    }
  }
  Future<void> detenerService()async{
    await FlutterForegroundTask.stopService();
  }
}
