import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ota_update/ota_update.dart';
import 'package:pidelofacil_moto/core/colores.dart';
import 'package:pidelofacil_moto/core/device.dart';
import 'package:pidelofacil_moto/core/dio_client.dart';
import 'package:pidelofacil_moto/core/funciones.dart';
import 'package:pidelofacil_moto/core/permisosFirebase.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/login_service.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/view_login.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';

class Principal extends StatefulWidget {
  final String usuario;
  const Principal({required this.usuario});

  @override
  State<Principal> createState() => _PrincipalState(usuario: usuario);
}

class _PrincipalState extends State<Principal> with WidgetsBindingObserver {
  InAppWebViewController? webViewController;
  PermisosFirebase permisosFirebase = PermisosFirebase();
  bool cargando = true;
  String? token;
  bool permisosOtorgados = false;
  final String usuario;
  bool gps_activo = true;

  _PrincipalState({required this.usuario});

  @override
  void initState() {
    super.initState();
    _cargarToken();
    _verificarPermisosFirebase();
    _mostrarNotificacionPrimerPlano();

    iniciarServicio();

    //verificarActualizacion();
  }

  Future<void> iniciarServicio() async {
    const platform = MethodChannel("gps_service");

    await platform.invokeMethod("startGPS", {
      "user_id": usuario,
      "token": await Funciones().getToken(),
    });
  }

  Future<void> verificarActualizacion() async {
    final s = await DioClient.dio.get("${Env.dominio}/getVersionApk");
    final version = s.data["version"] ?? "";
    final apkurl = s.data["apkurl"] ?? "";

    final nuevaActualizacion = await Funciones().verificarYActualizar(
      version,
      apkurl,
    );
    if (nuevaActualizacion) {
      actualizarApp(apkurl);
    }
  }

  void actualizarApp(String url) {
    OtaUpdate()
        .execute(url, destinationFilename: "pidelofacil.apk")
        .listen((event) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _enviarToken() async {
    final pr = await Funciones().getUsuarioId();
    final rs = await AuthService().saveToken(token ?? "", pr.toString());
  }

  Future<void> _mostrarNotificacionPrimerPlano() async {
    PermisosFirebase().escucharNotificaciones(context);
  }

  Future<void> _verificarPermisosFirebase() async {
    // Llamamos a tu singleton de permisos Firebase
    String? permiso = await permisosFirebase.init();

    if (permiso == null) {
      Future<void> mostrarAlerta(
        BuildContext context, {
        required String titulo,
        required String mensaje,
        IconData? icono,
        Color? colorIcono,
        List<Widget>? acciones, // Botones personalizados
      }) async {
        return showDialog(
          context: context,
          barrierDismissible: false, // Para que el usuario interactúe
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              title: Row(
                children: [
                  if (icono != null)
                    Icon(icono, color: colorIcono ?? Colors.blue, size: 28),
                  if (icono != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(mensaje, style: const TextStyle(fontSize: 16)),
              actions:
                  acciones ??
                  [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Aceptar"),
                    ),
                  ],
            );
          },
        );
      }

      await mostrarAlerta(
        context,
        titulo: "Permisos Necesarios",
        mensaje: "Debes otorgar permisos de notificación para continuar.",
        icono: Icons.notifications_active,
        colorIcono: Colors.orange,
        acciones: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await Funciones().abrirConfiguracionPermisos();
              Navigator.pop(context);
            },
            child: const Text(
              "Abrir configuración",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      );

      setState(() {
        permisosOtorgados = false;
      });
    } else {
      // Permisos otorgados
      setState(() {
        token = permiso;
        permisosOtorgados = true;
        _enviarToken();
      });
    }
  }

  Future<void> _cargarToken() async {
    final t = await Funciones().getToken();
    if (t == null || t.isEmpty) {
      return;
    }
    setState(() => token = t);
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colores.botones)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("${Env.dominio}/webview-login?token=$token"),
              ),

              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                geolocationEnabled: true,
                clearCache: false,
                clearSessionCache: false,
                sharedCookiesEnabled: true,
                thirdPartyCookiesEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              ),
              onGeolocationPermissionsShowPrompt: (controller, origin) async {
                return GeolocationPermissionShowPromptResponse(
                  origin: origin,
                  allow: true,
                  retain: true,
                );
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;

                if (uri != null) {
                  final url = uri.toString();

                  if (url.contains("google.com/maps") ||
                      url.contains("maps.google.com") ||
                      url.startsWith("geo:")) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );

                    return NavigationActionPolicy.CANCEL;
                  }
                }

                return NavigationActionPolicy.ALLOW;
              },
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },

              onLoadStop: (controller, url) async {
                debugPrint("✅ Cargó: $url");

                setState(() => cargando = false);
                const EventChannel gpsChannel = EventChannel("gps_location");

                gpsChannel.receiveBroadcastStream().listen((event) async {
                  final double lat = (event["lat"] as num).toDouble();
                  final double lng = (event["lng"] as num).toDouble();

                  if (webViewController != null) {
                    await webViewController!.evaluateJavascript(
                      source:
                          """
          if (typeof window.actualizarUbicacion === 'function') {
              window.actualizarUbicacion($lat, $lng);
          }
        """,
                    );
                  }
                });
              },

              onLoadError: (controller, url, code, message) {
                debugPrint("❌ Error WebView: $message");
                setState(() => cargando = false);
              },
            ),
          ),

          if (cargando)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: Colores.botones),
              ),
            ),
          if (!permisosOtorgados) ...[
            Container(
              color: Colors.white,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.botones, // Color del botón
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _verificarPermisosFirebase();
                  },
                  child: const Text(
                    "Otorgar Permisos",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
          if (!gps_activo) ...[
            if (!gps_activo) ...[
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.redAccent,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "GPS desactivado",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Para continuar, debes activar tu ubicación.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () async {
          if (!await Funciones().confirmacion(
            context: context,
            titulo: "¿Cerrar sesión?",
            mensaje: "Tu hora de salida será registrada. ¿Deseas continuar?",
          )) {
            return;
          }
          final userId = await Funciones().getUsuarioId();
          final uuid = await DeviceService.getDeviceUUID();
          final solicitud = await AuthService().logout(uuid, userId);
          if (solicitud.statusCode == 200 && solicitud.data["ok"] == true) {
            const platform = MethodChannel("gps_service");
            await platform.invokeMethod("stopGPS");
            //await Funciones().deleteUserTokens();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ViewLogin()),
            );
          } else {
            await Funciones().mostrarNotificacion(
              context: context,
              titulo: "Ocurrio un Error",
              mensaje: solicitud.data["mensaje"] ?? '',
              icono: Icons.error,
              colorIcono: Colors.redAccent,
            );
          }
        },
        child: Icon(Icons.logout),
      ),
    );
  }
}
