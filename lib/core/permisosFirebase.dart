import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pidelofacil_moto/core/funciones.dart';
import 'package:pidelofacil_moto/main.dart';

class PermisosFirebase {
  static final PermisosFirebase _instance = PermisosFirebase._internal();

  factory PermisosFirebase() {
    return _instance;
  }

  PermisosFirebase._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> init() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      return token;
    } else {
      return null;
    }
  }

  // 6️⃣ Escuchar notificaciones en primer plano
  void escucharNotificaciones(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) async {
      final data = mensaje.data;

      final String titulo = mensaje.notification?.title ?? 'Nueva notificación';

      final String cuerpo =
          mensaje.notification?.body ??
          Funciones().formatearMensajeDesdeData(data);
      await Funciones().reproducirSonido();
      await Funciones().mostrarNotificacion(
        context: context,
        titulo: titulo,
        mensaje: cuerpo,
        icono: Icons.notifications_active,
        colorIcono: Colors.orange,
        duracion: Duration(seconds: 10),
      );
    });
  }

  // 7️⃣ Escuchar cuando la app se abre desde la notificación
  void onNotificationOpened(Function(RemoteMessage) onOpenedCallback) {
    FirebaseMessaging.onMessageOpenedApp.listen(onOpenedCallback);
  }
}
