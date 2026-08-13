import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pidelofacil_moto/core/dio_client.dart';
import 'package:pidelofacil_moto/core/funciones.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/view_login.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage mensaje) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings android = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const InitializationSettings settings = InitializationSettings(
    android: android,
  );

  await localNotifications.initialize(settings: settings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'canal_general',
    'Notificaciones',
    description: 'Canal de notificaciones',
    importance: Importance.max,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final String titulo = mensaje.notification?.title ?? 'Nueva notificación';

  final String cuerpo =
      mensaje.notification?.body ??
          Funciones().formatearMensajeDesdeData(mensaje.data);

  await localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title:titulo,
    body:cuerpo,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'canal_general',
        'Notificaciones',
        channelDescription: 'Canal de notificaciones',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}



final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);


  DioClient.init();

  await initLocalNotifications();

  runApp(const MyApp());
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(android: android);

  await localNotifications.initialize(settings: settings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'canal_general',
    'Notificaciones',
    description: 'Canal de notificaciones',
    importance: Importance.max,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pidelo Facil',
          theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          home: ViewLogin(),
        );
      },
    );
  }
}
