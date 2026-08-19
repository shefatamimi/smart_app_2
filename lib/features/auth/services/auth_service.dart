import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/core/api_client.dart';
import 'package:smart_application/core/app_constants.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    try {
      // ============================================================
      // 1. تجهيز طلب تسجيل الدخول
      // ============================================================

      final data =
          "DataType:4,"
          "Where: and A.USER_NAME='$username' "
          "and A.USR_DFN_PASSWORD='$password' "
          "and b.app_id = 7";

      debugPrint("==============================================");
      debugPrint(">>> LOGIN");
      debugPrint(">>> USERNAME: $username");

      final encrypted = ApiClient.encryptRSA(data);

      final response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl,
        "GetAppLoginUser",
        encrypted,
      );

      debugPrint(">>> LOGIN RESPONSE:");
      debugPrint(response);
      debugPrint("==============================================");

      // ============================================================
      // 2. التأكد من نجاح الطلب
      // ============================================================

      if (!response.contains("GetAppLoginUserResult")) {
        debugPrint(">>> LOGIN FAILED: GetAppLoginUserResult NOT FOUND");
        return false;
      }

      if (response.toLowerCase().contains("error")) {
        debugPrint(">>> LOGIN FAILED: SERVER RETURNED ERROR");
        return false;
      }

      // ============================================================
      // 3. تحليل XML
      // ============================================================

      final doc = xml.XmlDocument.parse(response);

      final Map<String, String> userInfo = {};

      /*
       * نبحث في كامل XML عن العناصر التي تحتوي على بيانات المستخدم.
       *
       * لا نعتمد فقط على <Table>
       * لأن السيرفر قد يرجع:
       *
       * diffgram
       *   └── NewDataSet
       *       └── Table
       *
       * أو Table1 / Table2 ...
       */

      final allElements = doc.descendants.whereType<xml.XmlElement>();

      for (final element in allElements) {
        final tagName = element.name.local.toUpperCase();

        final text = element.innerText.trim();

        if (text.isEmpty) {
          continue;
        }

        /*
         * نأخذ الحقول المعروفة فقط.
         */
        if (_isUserField(tagName)) {
          userInfo[tagName] = text;

          debugPrint(
            ">>> USER FIELD: $tagName = [$text]",
          );
        }
      }

      // ============================================================
      // 4. طباعة جميع الحقول التي وجدناها
      // ============================================================

      debugPrint("==============================================");
      debugPrint(">>> EXTRACTED USER INFORMATION");
      debugPrint("==============================================");

      if (userInfo.isEmpty) {
        debugPrint(">>> NO USER FIELDS FOUND");
      } else {
        userInfo.forEach((key, value) {
          debugPrint(">>> $key = [$value]");
        });
      }

      debugPrint("==============================================");

      // ============================================================
      // 5. البحث عن رقم الموظف
      // ============================================================

      String empNo = _findEmployeeNumber(userInfo);

      // ============================================================
      // 6. البحث عن ID
      // ============================================================

      String userId = _firstNotEmpty([
        userInfo['USER_ID'],
        userInfo['ID'],
        userInfo['USERID'],
      ]);

      // ============================================================
      // 7. البحث عن الاسم
      // ============================================================

      String fullName = _firstNotEmpty([
        userInfo['USR_FULL_NAME'],
        userInfo['FULL_NAME'],
        userInfo['USER_NAME'],
        userInfo['NAME'],
      ]);

      // ============================================================
      // 8. Oracle User
      // ============================================================

      String oracleUser = _firstNotEmpty([
        userInfo['ORACLE_USER'],
        userInfo['ORACLE_USERNAME'],
      ]);

      // ============================================================
      // 9. طباعة النتيجة النهائية
      // ============================================================

      debugPrint("==============================================");
      debugPrint(">>> LOGIN PARSED DATA");
      debugPrint("==============================================");
      debugPrint(">>> USER ID       = [$userId]");
      debugPrint(">>> EMPLOYEE NO   = [$empNo]");
      debugPrint(">>> FULL NAME     = [$fullName]");
      debugPrint(">>> ORACLE USER   = [$oracleUser]");
      debugPrint("==============================================");

      // ============================================================
      // 10. حفظ البيانات
      // ============================================================

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'username',
        username,
      );

      await prefs.setString(
        'password',
        password,
      );

      await prefs.setString(
        'ID',
        userId,
      );

      await prefs.setString(
        'EMP_NO',
        empNo,
      );

      await prefs.setString(
        'ORACLE_USER',
        oracleUser,
      );

      await prefs.setString(
        'name',
        fullName,
      );

      // ============================================================
      // 11. التحقق مما تم تخزينه فعلياً
      // ============================================================

      debugPrint("==============================================");
      debugPrint(">>> SHARED PREFERENCES AFTER LOGIN");
      debugPrint("==============================================");

      debugPrint(
        ">>> username = [${prefs.getString('username')}]",
      );

      debugPrint(
        ">>> ID = [${prefs.getString('ID')}]",
      );

      debugPrint(
        ">>> EMP_NO = [${prefs.getString('EMP_NO')}]",
      );

      debugPrint(
        ">>> ORACLE_USER = [${prefs.getString('ORACLE_USER')}]",
      );

      debugPrint(
        ">>> name = [${prefs.getString('name')}]",
      );

      debugPrint("==============================================");

      // ============================================================
      // 12. نجاح تسجيل الدخول
      // ============================================================

      return true;
    } catch (e, stackTrace) {
      debugPrint("==============================================");
      debugPrint(">>> AUTH LOGIN ERROR");
      debugPrint(">>> $e");
      debugPrint("$stackTrace");
      debugPrint("==============================================");

      return false;
    }
  }

  // ================================================================
  // تحديد الحقول المهمة
  // ================================================================

  static bool _isUserField(String name) {
    const fields = {
      'EMP_NO',
      'USER_ID',
      'USERID',
      'ID',
      'ORACLE_USER',
      'ORACLE_USERNAME',
      'USR_FULL_NAME',
      'FULL_NAME',
      'USER_NAME',
      'NAME',
      'SYS_MINOR',
      'SYS_MAJOR',
      'EMPLOYEE_NO',
      'EMPLOYEENO',
      'EMPLOYEE_ID',
      'EMPLOYEEID',
    };

    return fields.contains(name);
  }

  // ================================================================
  // البحث عن رقم الموظف
  // ================================================================

  static String _findEmployeeNumber(
      Map<String, String> userInfo,
      ) {
    final possibleKeys = [
      'EMP_NO',
      'EMPLOYEE_NO',
      'EMPLOYEENO',
      'EMPLOYEE_ID',
      'EMPLOYEEID',
    ];

    for (final key in possibleKeys) {
      final value = userInfo[key];

      if (value != null && value.trim().isNotEmpty) {
        debugPrint(
          ">>> EMPLOYEE NUMBER FOUND USING: $key",
        );

        return value.trim();
      }
    }

    debugPrint(
      ">>> EMPLOYEE NUMBER NOT FOUND",
    );

    return '';
  }

  // ================================================================
  // إرجاع أول قيمة غير فارغة
  // ================================================================

  static String _firstNotEmpty(
      List<String?> values,
      ) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  // ================================================================
  // تغيير كلمة المرور
  // ================================================================

  static Future<String> updateUserPass(
      String newPass,
      String userId,
      ) async {
    try {
      final data =
          "pw:$newPass,"
          "id:$userId,"
          "datatype:2";

      final response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl,
        "Update_User_Pass",
        ApiClient.encryptRSA(data),
      );

      final document = xml.XmlDocument.parse(response);

      final result =
      document.findAllElements("Update_User_PassResult");

      return result.isNotEmpty
          ? result.first.innerText
          : "فشل تحديث كلمة المرور";
    } catch (e) {
      return "خطأ في الاتصال: $e";
    }
  }

  // ================================================================
  // تسجيل الخروج
  // ================================================================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    debugPrint(">>> USER LOGGED OUT");
  }
}