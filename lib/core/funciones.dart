import 'package:another_flushbar/flushbar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pidelofacil_moto/core/env.dart';

class Funciones {
  static void ocultarTeclado(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  Future<void> guardarToken(
    String token,
    String id_personal,
    String user,
  ) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: "token", value: token);
    await storage.write(key: 'user_id', value: id_personal);
    await storage.write(key: 'user_nombre', value: user);
  }

  Future<void> deleteUserTokens() async {
    final storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  Future<String> getToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: "token") ?? "";
  }

  Future<String> getUsuarioId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: "user_id") ?? "";
  }

  Future<void> abrirConfiguracionPermisos() async {
    bool opened = await openAppSettings();
    if (!opened) {
      print("No se pudo abrir la configuración de la app");
    }
  }

  Future<String> getVersionActual() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  bool esNuevaVersion(String actual, String servidor) {
    return actual != servidor;
  }
  Future<bool> verificarYActualizar(String version,String url) async {
    final versionActual = await getVersionActual();

    final versionServidor = version;
    final apkUrl = url;

    if (versionActual != versionServidor) {
      return true;
    }
    return false;
  }

  Future<void> mostrarAlerta(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    IconData? icono,
    Color? colorIcono,
    String textoBoton = "Aceptar",
    VoidCallback? onAceptar, // Acción personalizada para el botón
    String? textoBotonSecundario, // Segundo botón opcional
    VoidCallback? onBotonSecundario, // Acción para el segundo botón
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              if (icono != null) Icon(icono, color: colorIcono ?? Colors.blue),
              if (icono != null) SizedBox(width: 8),
              Expanded(child: Text(titulo)),
            ],
          ),
          content: Text(mensaje),
          actions: [
            if (textoBotonSecundario != null && onBotonSecundario != null)
              TextButton(
                onPressed: () {
                  onBotonSecundario();
                  Navigator.of(context).pop();
                },
                child: Text(textoBotonSecundario),
              ),
            TextButton(
              onPressed: () {
                if (onAceptar != null) onAceptar();
                Navigator.of(context).pop();
              },
              child: Text(textoBoton),
            ),
          ],
        );
      },
    );
  }

  String formatearMensajeDesdeData(Map<String, dynamic> data) {
    if (data['operacion'] == 'asignacion') {
      return 'Se te asignó un nuevo pedido #${data['pedido_id']} ⏱ ${data['tiempo']} min';
    }

    if (data['operacion'] == 'finalizado') {
      return 'Pedido finalizado correctamente';
    }

    if (data['operacion'] == 'pedido_tomado') {
      return 'Tu pedido fue tomado';
    }

    return 'Tienes una nueva actualización';
  }

  Future<bool> confirmacion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    IconData? icono,
    Color? colorIcono,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  if (icono != null)
                    Icon(icono, color: colorIcono ?? Colors.deepPurple),
                  if (icono != null) const SizedBox(width: 8),
                  Text(titulo),
                ],
              ),
              content: Text(mensaje),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.green),
                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Aceptar"),
                ),
              ],
            );
          },
        ) ??
        false; // si se cierra de otra manera, retorna false
  }

  Future<void> reproducirSonido() async {
    final player = AudioPlayer();
    player.setVolume(1.0);
    await player.play(AssetSource('sonidos/click.mp3'));
  }

  Future<void> mostrarNotificacion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    IconData? icono,
    Color? colorIcono,
    Duration duracion = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) async {
    Flushbar(
      title: titulo,
      message: mensaje,
      icon: icono != null
          ? Icon(icono, color: colorIcono ?? Colors.white, size: 28)
          : null,
      duration: duracion,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.deepPurple,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
      leftBarIndicatorColor: Colors.orange,
      onTap: (flushbar) {
        if (onTap != null) onTap();
      },
    ).show(context);
  }
}
