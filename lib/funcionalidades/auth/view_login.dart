import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pidelofacil_moto/core/colores.dart';
import 'package:pidelofacil_moto/core/funciones.dart';
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
  bool recordar_datos=false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await leerDatos();

    });
  }
  Future<void> leerDatos() async {
    final storage = FlutterSecureStorage();

    String? usuario = await storage.read(key: "usuario");
    String? pass = await storage.read(key: "pass");
    String? recordarValue = await storage.read(key: "recordar");

    bool recordar_datoss = recordarValue == "true";
    if(recordar_datoss){
      setState(() {
        emailCtrl.text=usuario!;
        passCtrl.text=pass!;
        recordar_datos=recordar_datoss;
      });
    }

  }
  Future<bool> pedirPermisosGPS() async {

    var location = await Permission.location.request();

    if (!location.isGranted) {
     await Funciones().mostrarNotificacion(
        context: context,
        titulo: "Permiso de ubicación requerido",
        mensaje: "Debes permitir el acceso a la ubicación para poder compartir tu ubicación.",
      );
      return false;
    }


    var always = await Permission.locationAlways.request();

    if (!always.isGranted) {

      await Funciones().mostrarNotificacion(
        context: context,
        titulo: "Activa ubicación en segundo plano",
        mensaje: "Ve a Ajustes > Permisos > Ubicación y selecciona 'Permitir siempre' para que podamos rastrear tu ubicación cuando la aplicación esté cerrada.",
      );

      return false;
    }


   return true;
  }

  Future<void> login() async {
    if(!await pedirPermisosGPS()){
     await Funciones().mostrarNotificacion(
        context: context,
        titulo: "Activa los permisos",
        mensaje: "Cierra la App y autoriza todos los permisos."
      );
     return;
    }

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
      if(recordar_datos){
        final storage=FlutterSecureStorage();
        await storage.write(key: "usuario", value: emailCtrl.text.trim());
        await storage.write(key: "pass", value: passCtrl.text.trim());
        await storage.write(key: "recordar", value: recordar_datos ? "true" : "false");

      }

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
            colors: [const Color(0xFF22C55E),Colores.fondo],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:  EdgeInsets.all(24.r),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// LOGO
                    Container(
                      padding:  EdgeInsets.all(20.r),
                      width: 0.5.sw,
                      height: 0.2.sh,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.2),
                            blurRadius: 10.r,
                          ),
                        ],
                      ),
                      child:  Image.asset(
                          "assets/entrega_nav.png",
                          fit: BoxFit.contain,
                          
                        
                      ),
                    ),

                     SizedBox(height: 10.h),

                     Text(
                      'PideloFácil',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle:FontStyle.italic ,
                        color: Colors.white,
                      ),
                    ),

                     SizedBox(height: 30.h),

                    /// CARD LOGIN
                    Container(
                      padding:  EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
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

                           SizedBox(height: 20.h),

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
                          SizedBox(height: 10.h,),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                           children: [
                             Checkbox(activeColor: Colors.green, value: recordar_datos, onChanged: (value) {
                               setState(() {
                                 recordar_datos=value!;
                               });
                             },),
                             Text("Recordar Datos")
                           ],
                          ),

                           SizedBox(height: 10.h),

                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: cargando ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colores.botones,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: cargando
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  :  Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        fontSize: 16.sp,
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
