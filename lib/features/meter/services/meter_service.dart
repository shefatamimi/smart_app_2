import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:smart_application/core/api_client.dart';
import 'package:smart_application/core/app_constants.dart';
import 'package:smart_application/features/meter/models/meter_event_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeterService {
  static Future<Map<String, String>?> getHomeInfo(String meterNum) async {
    try {
      debugPrint(">>> STEP 1: Getting Basic Meter Info for: $meterNum");

      // بناء نص الطلب كما هو متوقع في نظام IDECO
      String data1 = "DataType:6;Where:;mtrnum:$meterNum";

      // محاولة استخدام GetMeterInfo أولاً كما في الجافا، مع الرجوع لـ GetCustomerBillingInfoEnc كبديل
      String response1;
      try {
        response1 = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "GetMeterInfo", ApiClient.encryptRSA(data1));
        if (response1.toLowerCase().contains("error") || response1.contains("fault")) throw "Try fallback";
      } catch (e) {
        response1 = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "GetCustomerBillingInfoEnc", ApiClient.encryptRSA(data1));
      }

      final doc1 = xml.XmlDocument.parse(response1);
      
      // استخراج CityId و SubNum (مع دعم البدائل)
      String cityId = ApiClient.smartSearch(doc1, "MTR_CITY");
      if (cityId == "---") cityId = ApiClient.smartSearch(doc1, "CUSM_CITY");
      
      String subNum = ApiClient.smartSearch(doc1, "MTR_NUM");
      if (subNum == "---") subNum = ApiClient.smartSearch(doc1, "CUSM_NUM");

      if (cityId != "---" && subNum != "---") {
        // القاعدة الذهبية: CityId 3 خانات، و SubNum 7 خانات تبدأ بـ 0
        String paddedCityId = cityId.trim().padLeft(3, '0');
        String paddedSubNum = subNum.trim().padLeft(7, '0');
        
        debugPrint(">>> INVOICE PLAIN DATA: DataType:9,CityId:$paddedCityId,SubNum:$paddedSubNum");
        
        String data2 = "DataType:9,CityId:$paddedCityId,SubNum:$paddedSubNum";
        String response2 = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "GetInvoicesInfoEnc", ApiClient.encryptRSA(data2));

        final doc2 = xml.XmlDocument.parse(response2);

        // الوصول لـ NewDataSet (المستوى 2 في الجافا)
        final newDataSet = doc2.findAllElements('NewDataSet').firstOrNull;
        
        // إذا لم نجد NewDataSet نبحث عن أي عنصر يحتوي على BIL_NUM
        final rows = newDataSet != null 
            ? newDataSet.children.whereType<xml.XmlElement>()
            : doc2.descendants.whereType<xml.XmlElement>().where((e) => e.findElements('BIL_NUM').isNotEmpty);

        debugPrint(">>> Parsed ${rows.length} rows from XML");

        double totalSum = 0.0;
        int unpaidCount = 0;

        for (var row in rows) {
          // الشرط: PAYFLAG (كلمة واحدة، أحرف كبيرة) يساوي "0"
          String payFlag = ApiClient.smartSearch(row, "PAYFLAG");

          if (payFlag == "0") {
            // الجمع من BIL_REMAIN (المبلغ المتبقي)
            String remainStr = ApiClient.smartSearch(row, "BIL_REMAIN");
            double amount = double.tryParse(remainStr) ?? 0.0;

            totalSum += amount;
            unpaidCount++;

            // التقريب لـ 3 خانات عشرية في كل خطوة (مهم جداً للمطابقة مع الجافا)
            totalSum = double.parse(totalSum.toStringAsFixed(3));
          }
        }

        // تجميع البيانات النهائية بتنسيق متوافق مع HomeScreen
        Map<String, String> finalInfo = {};

        // 1. معلومات المشترك والعداد (مطابقة لـ HomeInfoAsyncCall.java)
        finalInfo['display_name'] = ApiClient.smartSearch(doc1, "CUSM_NAME");
        finalInfo['display_id'] = paddedCityId + paddedSubNum;
        finalInfo['display_meter'] = ApiClient.smartSearch(doc1, "MTR_M_NUM");

        // 2. هاتف القارئ والمشترك
        String rdrMobile = ApiClient.smartSearch(doc1, "RDRM_MOBILE_NO");
        finalInfo['display_mobile'] = (rdrMobile != "---" && rdrMobile.isNotEmpty) ? "0$rdrMobile" : "غير متوفر";
        finalInfo['CUSM_TELEPHONE'] = ApiClient.smartSearch(doc1, "CUSM_TELEPHONE");

        // 3. الفاز (FAZ) ونوع العداد
        String fazVal = ApiClient.smartSearch(doc1, "FAZ");
        finalInfo['display_faz'] = fazVal != "---" ? "$fazVal فاز" : "غير متوفر";
        String smartVal = ApiClient.smartSearch(doc1, "SMART");
        finalInfo['display_smart'] = smartVal == "0" ? "غير ذكي" : "ذكي";
        finalInfo['SMART'] = smartVal;

        // 4. المنطقة وموعد القراءة والموقع الجغرافي
        finalInfo['display_area'] = ApiClient.smartSearch(doc1, "REGM_NAME");
        finalInfo['reading_date'] = ApiClient.smartSearch(doc1, "READING_DATE");
        finalInfo['POS_X'] = ApiClient.smartSearch(doc1, "POS_X");
        finalInfo['POS_Y'] = ApiClient.smartSearch(doc1, "POS_Y");

        // 5. الحالة وتفاصيل الفصل (مهمة لشاشة إنشاء الوصل)
        finalInfo['state'] = ApiClient.smartSearch(doc1, "STATUS_DESC");
        finalInfo['STATUS_DESC'] = finalInfo['state']!;
        finalInfo['SEP_TYPE_DESC'] = ApiClient.smartSearch(doc1, "SEP_TYPE_DESC");
        finalInfo['SEP_DATE'] = ApiClient.smartSearch(doc1, "SEP_DATE");

        // 6. الفواتير والذمم المحسوبة بدقة (Logic: CalcSum)
        finalInfo['INVOICE_COUNT'] = unpaidCount.toString();
        finalInfo['display_inv_amt'] = totalSum.toStringAsFixed(3);

        // قيم تقنية مخفية للعمليات اللاحقة
        finalInfo['MTR_CITY'] = paddedCityId;
        finalInfo['MTR_NUM'] = paddedSubNum;
        finalInfo['MTR_KIND'] = ApiClient.smartSearch(doc1, "KIND");
        finalInfo['MTR_NUM_ORIGINAL'] = subNum; 

        return finalInfo;
      }
      return null;
    } catch (e) {
      debugPrint("METER INFO ERROR: $e");
      return null;
    }
  }

  static Future<List<MeterEventItem>> getMeterEvents(String meterMNum, String fromDate, String endDate) async {
    try {
      // رقم العداد بدون أول حرفين كما في الجافا
      String mNum = meterMNum.length > 2 ? meterMNum.substring(2) : meterMNum;
      String data = "meterNo:$mNum,from:$fromDate,to:$endDate";
      String response = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "GetMeterEvents", ApiClient.encryptRSA(data));

      final document = xml.XmlDocument.parse(response);
      final tables = document.descendants.whereType<xml.XmlElement>().where((e) => e.name.local.toLowerCase() == "table");

      List<MeterEventItem> list = [];
      for (var table in tables) {
        Map<String, String> row = {};
        for (var child in table.children.whereType<xml.XmlElement>()) {
          row[child.name.local] = child.innerText.trim();
        }
        if (row.isNotEmpty) list.add(MeterEventItem.fromMap(row));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<String?> getMeterNumberBySubscriber(String subscriberId) async {
    try {
      // بناء استعلام البحث برقم الاشتراك (مطابق تماماً لمتطلبات السيرفر)
      String data = "DataType:4;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '$subscriberId';mtrnum:$subscriberId";
      String response = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "GetCustomerBillingInfoEnc", ApiClient.encryptRSA(data));

      final document = xml.XmlDocument.parse(response);
      String mtrNum = ApiClient.smartSearch(document, "MTR_M_NUM");

      return mtrNum != "---" ? mtrNum : null;
    } catch (e) {
      return null;
    }
  }

  /// فحص حالة العداد الآن (Connected, Disconnected, Offline)
  static Future<String> getMeterState(String meterNo, String kind) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String oracleUser = prefs.getString('ORACLE_USER') ?? "";
      
      // رقم العداد بدون أول حرفين كما في CheckMeter(meterNo.substring(2))
      String mNum = meterNo.length > 2 ? meterNo.substring(2) : meterNo;

      // بناء جملة الاستعلام تماماً كما في الجافا
      String data = "meterNo:$mNum,meterType:$kind,DataType:2,MtrStatus:'',tranType:6,orcUser:$oracleUser";

      debugPrint(">>> METER STATE DATA: $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl,
        "ControlSmartMeter",
        ApiClient.encryptRSA(data)
      );

      debugPrint(">>> METER STATE RAW: $response");

      if (response.isEmpty) return "رد فارغ من السيرفر";

      final document = xml.XmlDocument.parse(response);

      // البحث بمرونة عن النتيجة (تجاهل حالة الأحرف والـ Namespaces)
      final resultElement = document.descendants
          .whereType<xml.XmlElement>()
          .where((e) => e.name.local.toLowerCase() == "controlsmartmeterresult")
          .firstOrNull;

      if (resultElement != null) {
        String state = resultElement.innerText.trim();
        return state.isNotEmpty ? state : "الحالة فارغة";
      }

      // إذا لم نجد الحقل المتوقع، نبحث عن أي خطأ (Fault) في الـ XML
      final faultElement = document.findAllElements("faultstring").firstOrNull;
      if (faultElement != null) return "خطأ سيرفر: ${faultElement.innerText}";

      return "تنسيق غير معروف: ${response.length > 50 ? response.substring(0, 50) : response}";
    } catch (e) {
      debugPrint("METER STATE ERROR: $e");
      return "خطأ استثناء: $e";
    }
  }

  /// جلب قيمة الفولتية الحالية للعداد
  /// يتطلب أن يكون العداد متصلاً (Connected)
  static Future<String> getMeterVoltage(String meterNo) async {
    try {
      // رقم العداد بدون أول حرفين كما في متطلبات سيرفر IDECO
      String mNum = meterNo.length > 2 ? meterNo.substring(2) : meterNo;

      // بناء نص الطلب بناءً على الكود المذكور في MeterVoltage.java
      // OBIS Code الافتراضي كما هو في الكود الأصلي
      String obisCode = "0100010800FF";
      
      // التنسيق المتوقع للبيانات: type:1,meterNo:...,OBISCode:...,value:0
      String data = "type:1,meterNo:$mNum,OBISCode:$obisCode,value:0";

      debugPrint(">>> GET VOLTAGE DATA: $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl,
        "GetMeterVoltage",
        ApiClient.encryptRSA(data)
      );

      debugPrint(">>> GET VOLTAGE RAW: $response");

      final document = xml.XmlDocument.parse(response);
      final resultElement = document.descendants
          .whereType<xml.XmlElement>()
          .where((e) => e.name.local.toLowerCase() == "getmetervoltageresult")
          .firstOrNull;

      if (resultElement != null) {
        String voltage = resultElement.innerText.trim();
        return voltage.isNotEmpty ? voltage : "0.0";
      }

      return "فشل في استخراج القيمة";
    } catch (e) {
      debugPrint("METER VOLTAGE ERROR: $e");
      return "خطأ: $e";
    }
  }

  /// جلب سجل الفواتير التقني للعداد ضمن فترة زمنية
  static Future<String> getMeterBilling(String meterNo, String fromDate, String toDate) async {
    try {
      // رقم العداد بدون أول حرفين كما في الجافا
      String mNum = meterNo.length > 2 ? meterNo.substring(2) : meterNo;
      
      // بناء نص الطلب (meterNo, from, to)
      String data = "meterNo:$mNum,from:$fromDate,to:$toDate";
      
      debugPrint(">>> GET METER BILLING DATA: $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "GetMeterBilling", 
        ApiClient.encryptRSA(data)
      );

      final document = xml.XmlDocument.parse(response);
      
      // نبحث عن NewDataSet الذي يحتوي على سجلات الفواتير
      final dataSet = document.descendants.whereType<xml.XmlElement>()
          .firstWhere((e) => e.name.local.toLowerCase() == "newdataset", 
          orElse: () => document.rootElement);

      final rows = dataSet.children.whereType<xml.XmlElement>();
      
      if (rows.isEmpty) return "لا توجد سجلات فواتير تقنية لهذه الفترة.";

      String result = "";
      for (var row in rows) {
        String rowText = "";
        for (var child in row.children.whereType<xml.XmlElement>()) {
          rowText += "${child.name.local}: ${child.innerText.trim()}\n";
        }
        if (rowText.isNotEmpty) {
          result += "$rowText\n-------------------\n\n";
        }
      }
      
      return result.isNotEmpty ? result : "رد فارغ من السيرفر";
    } catch (e) {
      debugPrint("METER BILLING ERROR: $e");
      return "حدث خطأ أثناء جلب الفواتير: $e";
    }
  }

  /// توثيق تغيير أوضاع العداد (مثل تفعيل/إلغاء الإنارة) في السيرفر
  static Future<String> recordModeLog(int type, String meterNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String oracleUser = prefs.getString('ORACLE_USER') ?? "";
      
      // بناء نص الطلب كما في الجافا
      // type: 6 لتفعيل الإنارة، 5 للإلغاء
      String data = "type:$type,meterNo:$meterNo,orcUser:$oracleUser";
      
      debugPrint(">>> MODE LOG DATA: $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "ModeLog", 
        ApiClient.encryptRSA(data)
      );

      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ModeLogResult").firstOrNull;
      
      return result?.innerText ?? "تم التوثيق بنجاح";
    } catch (e) {
      return "خطأ توثيق: $e";
    }
  }

  /// تسجيل حدث في السيرفر (SmartMeterEvent) كما في كود Java الأصلي
  static Future<void> logSmartMeterEvent(String meterNo, String userName, String eventDesc) async {
    try {
      String data = "meterNo:$meterNo,userName:$userName,eventDesc:$eventDesc";
      debugPrint(">>> LOGGING EVENT: $eventDesc for $meterNo");
      
      await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "SmartMeterEvent", 
        ApiClient.encryptRSA(data)
      );
    } catch (e) {
      debugPrint("LOG SMART METER EVENT ERROR: $e");
    }
  }
}
