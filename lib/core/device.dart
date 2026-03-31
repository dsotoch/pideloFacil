import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceUUID() async {
    String raw;

    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      raw = '${android.id}-${android.model}-${android.manufacturer}';
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      raw = '${ios.identifierForVendor}-${ios.utsname.machine}';
    } else {
      raw = 'unknown-device';
    }

    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }
  static Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      return {
        'modelo': '${android.manufacturer} ${android.model}',
        'plataforma': 'android',
      };
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      return {
        'modelo': ios.utsname.machine,
        'plataforma': 'ios',
      };
    } else {
      return {
        'modelo': 'unknown',
        'plataforma': 'unknown',
      };
    }
  }

}
