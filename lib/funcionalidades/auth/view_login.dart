import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:pidelofacil_moto/core/colores.dart';
import 'package:pidelofacil_moto/core/funciones.dart';
import 'package:pidelofacil_moto/funcionalidades/auth/gps_service.dart';
import 'package:pidelofacil_moto/funcionalidades/principal/principal.dart';
import '../../core/device.dart';
import 'login_service.dart';

class ViewLogin extends StatefulWidget {
  const ViewLogin({super.key});

  @override
  State<ViewLogin> createState() => _ViewLoginState();
}

class _ViewLoginState extends State<ViewLogin> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AuthService authService = AuthService();

  bool cargando = false;
  bool ocultarPass = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ServiceGps().requestPermissions();
    });
;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => cargando = true);

    final uuid = await DeviceService.getDeviceUUID();
    final info = await DeviceService.getDeviceInfo();

    try {
      if (!await isgpsActivo()) {
        await Funciones().mostrarNotificacion(
          context: context,
          titulo: "Requerimiento faltante",
          mensaje: "Es Necesario que actives tu Ubicación",
          icono: Icons.error,
          colorIcono: Colors.redAccent,
        );
        return;
      }
      final res = await authService.login(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
        uuid,
        info["modelo"] ?? "-",
        info["plataforma"] ?? "-",
      );

      if (res.statusCode == 200 && res.data['ok'] == true) {
        final data = res.data;
        if (data["ok"] == true &&
            data["token"] != null &&
            data["usuario"] != null) {
          await Funciones().guardarToken(
            data["token"].toString(),
            data["usuario"]["id"].toString(),
            data["usuario"]["nombre"].toString(),
          );
        }
        await ServiceGps().requestPermissions();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Principal(usuario: data["usuario"]["id"].toString()),
          ),
        );
      } else {
        _error(res.data['mensaje'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      _error('Error de conexión');
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<bool> isgpsActivo() async {
    return await FlLocation.isLocationServicesEnabled;
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colores.fondo, const Color(0xFF22C55E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// LOGO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        size: 70,
                        color: Colores.fondo,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'PideloFácil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// CARD LOGIN
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _input(
                              'Numero Telefonico',
                              Icons.phone_iphone,
                            ),
                            validator: (v) => v!.isEmpty
                                ? 'Ingrese el numero telefonico'
                                : null,
                          ),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: passCtrl,
                            obscureText: ocultarPass,
                            decoration: _input(
                              'Contraseña',
                              Icons.lock,
                              suffix: IconButton(
                                icon: Icon(
                                  ocultarPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => ocultarPass = !ocultarPass),
                              ),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Ingrese contraseña' : null,
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: cargando ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colores.botones,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: cargando
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
