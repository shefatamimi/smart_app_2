import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';

class GPRSService {
  static const MethodChannel _channel = MethodChannel('com.ideco.sync/data');

  /// تفعيل GPRS عبر البروب وتوثيق العملية في السيرفر
  static Future<String> activateGPRS({
    required String bluetoothAddress,
    required String bluetoothName,
    required Map<String, String> meterInfo,
  }) async {
    try {
      // 1. استدعاء الكود الأصلي (Native) لإرسال أوامر Hex للعداد
      final String result = await _channel.invokeMethod('enableGPRS', {
        'address': bluetoothAddress,
        'name': bluetoothName,
      });

      if (result == "تم تفعيل GPRS بنجاح") {
        // 2. توثيق العملية في السيرفر (ProbeGPRSConnTrans)
        final prefs = await SharedPreferences.getInstance();
        final empNo = prefs.getString('EMP_NO') ?? "";
        final empName = prefs.getString('ORACLE_USER') ?? "";
        
        final serverResult = await DirectCurrentService.probeGPRSConnTrans(
          meterNum: meterInfo['display_meter'] ?? "",
          workshopId: empNo,
          workshopName: empName,
          userName: empName,
          cityId: meterInfo['city_id'] ?? "0",
          custId: meterInfo['cust_id'] ?? "0",
        );

        return "تم التفعيل والتوثيق: $serverResult";
      } else {
        return result;
      }
    } on PlatformException catch (e) {
      return "خطأ في الاتصال بالبلوتوث: ${e.message}";
    } catch (e) {
      return "خطأ غير متوقع: $e";
    }
  }

  /// الاستعلام عن حالة العداد (Connected / Disconnected)
  static Future<String> checkMeterStatus({
    required String bluetoothAddress,
    required String bluetoothName,
  }) async {
    try {
      final String status = await _channel.invokeMethod('checkMeterStatus', {
        'address': bluetoothAddress,
        'name': bluetoothName,
      });
      return status;
    } on PlatformException catch (e) {
      return "Error: ${e.message}";
    } catch (e) {
      return "Error: $e";
    }
  }
}
