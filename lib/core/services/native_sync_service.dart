import 'package:flutter/services.dart';

class NativeSyncService {
  static const MethodChannel _channel = MethodChannel('com.ideco.sync/data');

  /// استدعاء منطق المزامنة الأصلي من الأندرويد (تشفير RSA + SOAP)
  /// [type] يمكن أن يكون 'connect' أو 'disconnect'
  static Future<String> performNativeSync(String type) async {
    try {
      final String result = await _channel.invokeMethod('syncOfflineData', {
        'type': type,
      });
      return result;
    } on PlatformException catch (e) {
      return "خطأ في الاتصال بالنظام الأصلي: ${e.message}";
    } catch (e) {
      return "خطأ غير متوقع: $e";
    }
  }
}
