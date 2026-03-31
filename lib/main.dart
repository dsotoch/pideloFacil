import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pidelofacil_moto/core/dio_client.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/gps_service_task.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/view_login.dart';
import 'firebase_options.dart';
import 'funcionalidades/auth/gps_service.dart';
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(GpsService());
}

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ServiceGps().initService();
  DioClient.init();
  _initFirebase();
  await initLocalNotifications();
  runApp(const MyApp());

}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(android: android);

  await localNotifications.initialize(settings: settings);
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pidelo Facil',
      theme: ThemeData(

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ViewLogin(),
    );
  }
}
