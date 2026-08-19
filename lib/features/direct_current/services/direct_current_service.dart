import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:smart_application/core/api_client.dart';
import 'package:smart_application/core/app_constants.dart';
import 'package:smart_application/features/direct_current/models/direct_current_item.dart';

class DirectCurrentService {
  static Future<String> connTrans({
    required String meterNum,
    required String workshopId,
    required String workshopName,
    required String userName,
    required String cityId,
    required String custId,
    required double lat,
    required double lng,
  }) async {
    try {
      String data = "strMTR_NUM:$meterNum,intWorkshopID:$workshopId,strWorkshopName:$workshopName,strOraUserName:$userName,CityId:$cityId,CustId:$custId,Lat:$lat,Lng:$lng";
      String response = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "ConnTrans", ApiClient.encryptRSA(data));
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ConnTransResult");
      return result.isNotEmpty ? result.first.innerText : "فشل العملية";
    } catch (e) {
      return "خطأ: $e";
    }
  }

  /// إنشاء حركة فصل وإرسالها للسيرفر
  static Future<String> disConnTrans({
    required String meterNum,
    required String workshopId,
    required String workshopName,
    required String userName,
    required String cityId,
    required String custId,
    required String kind,
    required String reason,
    required String notes,
    required double lat,
    required double lng,
  }) async {
    try {
      // بناء نص الطلب كما هو في الجافا تماماً
      String data = "strMTR_NUM:$meterNum,intWorkshopID:$workshopId,strWorkshopName:$workshopName,strOraUserName:$userName,CityId:$cityId,CustId:$custId,DisconnKind:$kind,DisconnReason:$reason,strDisconnReson:$notes,Lat:$lat,Lng:$lng";
      
      debugPrint(">>> DISCONNECTION REQUEST DATA: $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "DisConnTrans", 
        ApiClient.encryptRSA(data)
      );
      
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("DisConnTransResult");
      
      return result.isNotEmpty ? result.first.innerText : "فشل إرسال الحركة";
    } catch (e) {
      return "خطأ سيرفر: $e";
    }
  }

  static Future<String> probeConnTrans(String encryptedData) async {
    try {
      String response = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "ProbeConnTrans", encryptedData);
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ProbeConnTransResult");
      return result.isNotEmpty ? result.first.innerText : "فشل المزامنة";
    } catch (e) {
      return "خطأ: $e";
    }
  }

  static Future<String> probeDisConnTrans(String encryptedData) async {
    try {
      String response = await ApiClient.makeSoapRequest(AppConstants.baseUrl, "ProbeDisConnTrans", encryptedData);
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ProbeDisConnTransResult");
      return result.isNotEmpty ? result.first.innerText : "فشل المزامنة";
    } catch (e) {
      return "خطأ: $e";
    }
  }

  /// توثيق عملية تفعيل GPRS عبر البروب في السيرفر
  static Future<String> probeGPRSConnTrans({
    required String meterNum,
    required String workshopId,
    required String workshopName,
    required String userName,
    required String cityId,
    required String custId,
  }) async {
    try {
      // بناء نص الطلب كما هو في الجافا
      String data = "strMTR_NUM:$meterNum,intWorkshopID:$workshopId,strWorkshopName:$workshopName,strOraUserName:$userName,CityId:$cityId,CustId:$custId";
      
      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "ProbeGPRSConnTrans", 
        ApiClient.encryptRSA(data)
      );
      
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ProbeGPRSConnTransResult");
      
      return result.isNotEmpty ? result.first.innerText : "فشل توثيق العملية";
    } catch (e) {
      return "خطأ سيرفر: $e";
    }
  }

  /// توثيق عملية "وصل العداد" في السيرفر بعد نجاحها عبر البروب
  static Future<String> recordProbeConnection({
    required String meterNum,
    required String workshopId,
    required String workshopName,
    required String userName,
    required String cityId,
    required String custId,
  }) async {
    try {
      String data = "strMTR_NUM:$meterNum,intWorkshopID:$workshopId,strWorkshopName:$workshopName,strOraUserName:$userName,CityId:$cityId,CustId:$custId";
      
      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "ProbeConnTrans", 
        ApiClient.encryptRSA(data)
      );
      
      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("ProbeConnTransResult");
      
      return result.isNotEmpty ? result.first.innerText : "تم الوصل بنجاح (فشل التوثيق)";
    } catch (e) {
      return "خطأ توثيق: $e";
    }
  }

  static Future<int> insertDirectCurrent(Map<String, dynamic> params) async {
    try {
      String soapEnvelope = '''<v:Envelope xmlns:v="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><v:Header/><v:Body><tem:INSERT_DIRECT_CURRENT_APP><tem:ENTRY_EMP_NO>${params['ENTRY_EMP_NO']}</tem:ENTRY_EMP_NO><tem:CUSM_CITY>${params['CUSM_CITY']}</tem:CUSM_CITY><tem:CUSM_NUM>${params['CUSM_NUM']}</tem:CUSM_NUM><tem:CUSM_NAME>${params['CUSM_NAME']}</tem:CUSM_NAME><tem:MTR_M_NUM>${params['MTR_M_NUM']}</tem:MTR_M_NUM><tem:MTR_PHASE>${params['MTR_PHASE']}</tem:MTR_PHASE><tem:MTR_IS_SMART>${params['MTR_IS_SMART']}</tem:MTR_IS_SMART><tem:MTR_LOCATION>${params['MTR_LOCATION']}</tem:MTR_LOCATION><tem:UNPAID_BILL_AMT>${params['UNPAID_BILL_AMT']}</tem:UNPAID_BILL_AMT><tem:REGION_DESC>${params['REGION_DESC']}</tem:REGION_DESC><tem:READER_MOBILE>${params['READER_MOBILE']}</tem:READER_MOBILE><tem:ENG_WRKSHP_NO>${params['ENG_WRKSHP_NO']}</tem:ENG_WRKSHP_NO><tem:ENG_NAME>${params['ENG_NAME']}</tem:ENG_NAME><tem:EMP_NOTES>${params['EMP_NOTES']}</tem:EMP_NOTES></tem:INSERT_DIRECT_CURRENT_APP></v:Body></v:Envelope>''';
      final response = await http.post(Uri.parse(AppConstants.baseUrl), headers: {"Content-Type": "text/xml; charset=utf-8", "SOAPAction": "http://tempuri.org/IBillingWcfsrv/INSERT_DIRECT_CURRENT_APP"}, body: utf8.encode(soapEnvelope)).timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final result = document.findAllElements("INSERT_DIRECT_CURRENT_APPResult");
        if (result.isNotEmpty) return int.tryParse(result.first.innerText) ?? 0;
      }
      return 0;
    } catch (e) { return -1; }
  }

  static Future<List<DirectCurrentItem>> getDirectCurrentList(String whereClause) async {
    try {
      debugPrint(">>> SENDING DC REQUEST WITH WHERE: $whereClause");

      // بناء الـ XML - الباراميترات (tem:) ضرورية جداً في سيرفرات .NET لضمان وصول القيم
      String soapEnvelope = '''
<v:Envelope xmlns:v="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <v:Header/>
   <v:Body>
      <tem:GET_GET_DIRECT_CURRENT_APP>
         <tem:iDataType>2</tem:iDataType>
         <tem:sWhere><![CDATA[$whereClause]]></tem:sWhere>
      </tem:GET_GET_DIRECT_CURRENT_APP>
   </v:Body>
</v:Envelope>''';

      final response = await http.post(
        Uri.parse(AppConstants.baseUrl),
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction": "http://tempuri.org/IBillingWcfsrv/GET_GET_DIRECT_CURRENT_APP"
        },
        body: utf8.encode(soapEnvelope)
      ).timeout(const Duration(seconds: 45));

      debugPrint(">>> DC RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);

        // البحث عن الحاوية الأساسية للبيانات (NewDataSet) كما في .NET
        final dataSet = doc.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toLowerCase() == "newdataset")
            .firstOrNull;

        Iterable<xml.XmlElement> rows;
        if (dataSet != null) {
          // إذا وجدت الحاوية، فكل أبنائها هم سجلات (Rows)
          rows = dataSet.children.whereType<xml.XmlElement>();
        } else {
          // fallback: البحث عن أي عنصر يحتوي على حقول المعاملة المعروفة
          rows = doc.descendants.whereType<xml.XmlElement>().where((e) {
            final children = e.children.whereType<xml.XmlElement>().map((c) => c.name.local.toUpperCase());
            return children.contains("ID") || children.contains("MTR_M_NUM");
          });
        }

        List<DirectCurrentItem> list = [];
        for (var row in rows) {
          Map<String, String> data = {};
          for (var child in row.children.whereType<xml.XmlElement>()) {
            data[child.name.local.toUpperCase()] = child.innerText.trim();
          }
          if (data.isNotEmpty && (data.containsKey('ID') || data.containsKey('MTR_M_NUM'))) {
            list.add(DirectCurrentItem.fromMap(data));
          }
        }

        debugPrint(">>> Successfully parsed ${list.length} direct current records");
        return list;
      } else {
        debugPrint(">>> SERVER ERROR: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("GET DC LIST ERROR: $e");
      return [];
    }
  }

  /// جلب قائمة المهندسين باستخدام GetIDECO_WorkshopMF كما في كود Java الأصلي
  static Future<List<Map<String, String>>> getEngineers() async {
    try {
      String data = "wrk_type:34,office_id:0,minor:0,datatype:3";
      
      // استخدام GetIDECO_WorkshopMF بدلاً من GetSmartGenerics لمطابقة كود Java
      String response = await ApiClient.makeSoapRequest(
          AppConstants.baseUrl, "GetIDECO_WorkshopMF", ApiClient.encryptRSA(data));

      if (response.isEmpty) return [];
      xml.XmlDocument document = xml.XmlDocument.parse(response);
      
      final allElements = document.descendants.whereType<xml.XmlElement>();
      List<Map<String, String>> list = [];
      Set<String> seenIds = {};

      for (var element in allElements) {
        final nameNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'WRK_NAME').firstOrNull;
        final noNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'WRK_NO').firstOrNull;

        if (nameNode != null && noNode != null) {
          String name = nameNode.innerText.trim();
          String no = noNode.innerText.trim();
          
          if (name.isNotEmpty && name != "anyType{}" && !seenIds.contains(no)) {
            list.add({"id": no, "name": "$name - $no"});
            seenIds.add(no);
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint("GET ENGINEERS ERROR: $e");
      return [];
    }
  }

  /// جلب أسباب تأمين التيار باستخدام GetGenericsDataTable كما في كود Java الأصلي
  static Future<List<Map<String, String>>> getDirectReasons() async {
    try {
      // DataType:73,SYSMajor:699 كما في كود Java
      String data = "DataType:73,SYSMajor:699";
      
      // استخدام GetGenericsDataTable بدلاً من GetSmartGenerics لمطابقة كود Java
      String response = await ApiClient.makeSoapRequest(
          AppConstants.baseUrl, "GetGenericsDataTable", ApiClient.encryptRSA(data));

      if (response.isEmpty) return [];
      xml.XmlDocument document = xml.XmlDocument.parse(response);
      
      final allElements = document.descendants.whereType<xml.XmlElement>();
      List<Map<String, String>> list = [];
      Set<String> seenNames = {};

      for (var element in allElements) {
        final descNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'SYS_DESC').firstOrNull;
        final minorNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'SYS_MINOR').firstOrNull;

        if (descNode != null) {
          String desc = descNode.innerText.trim();
          String minor = minorNode?.innerText.trim() ?? desc;
          
          if (desc.isNotEmpty && desc != "anyType{}" && !seenNames.contains(desc)) {
            list.add({"id": minor, "name": desc});
            seenNames.add(desc);
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint("GET REASONS ERROR: $e");
      return [];
    }
  }

  /// جلب الثوابت (أنواع وأسباب الفصل) من السيرفر بتنسيق IDECO الدقيق
  static Future<List<Map<String, String>>> getSmartGenerics(int dataType) async {
    try {
      // التنسيق الصحيح المعتمد في IDECO: DataType:XX,SYSMajor:0,SYSMinor:0,SYSDesc:
      String data = "DataType:$dataType,SYSMajor:0,SYSMinor:0,SYSDesc:";
      
      debugPrint(">>> GET GENERICS REQ ($dataType): $data");

      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "GetSmartGenerics", 
        ApiClient.encryptRSA(data)
      );

      if (response.isEmpty || response.contains("fault")) return [];

      xml.XmlDocument document;
      try {
        document = xml.XmlDocument.parse(response);
      } catch (e) {
        return [];
      }
      
      // فك التغليف إذا كان الرد XML داخل String (Common in .NET)
      final resultElement = document.descendants.whereType<xml.XmlElement>()
          .where((e) => e.name.local.toLowerCase().contains("result")).firstOrNull;
      
      if (resultElement != null && resultElement.innerText.trim().startsWith("<")) {
          try {
            document = xml.XmlDocument.parse(resultElement.innerText.trim());
          } catch (_) {}
      }

      List<Map<String, String>> list = [];
      Set<String> uniqueIds = {}; 

      // البحث عن SYS_MINOR و SYS_DESC بأي حالة أحرف
      final allElements = document.descendants.whereType<xml.XmlElement>();
      
      for (var element in allElements) {
        final minorNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'SYS_MINOR').firstOrNull;
        final descNode = element.descendants.whereType<xml.XmlElement>()
            .where((e) => e.name.local.toUpperCase() == 'SYS_DESC').firstOrNull;

        if (minorNode != null && descNode != null) {
          String minor = minorNode.innerText.trim();
          String desc = descNode.innerText.trim();

          if (minor.isNotEmpty && minor != "anyType{}" && 
              desc.isNotEmpty && desc != "anyType{}" && 
              !uniqueIds.contains(minor)) {
            
            list.add({"id": minor, "name": desc});
            uniqueIds.add(minor);
          }
        }
      }
      
      // إذا كانت القائمة فارغة والنوع 11 أو 12، نجرب الأرقام القديمة 72 و 36
      if (list.isEmpty && (dataType == 11 || dataType == 12)) {
          int fallbackType = (dataType == 11) ? 72 : 36;
          debugPrint(">>> Empty results for $dataType, trying fallback: $fallbackType");
          return await getSmartGenerics(fallbackType);
      }

      debugPrint(">>> Final Parsed Generics Count ($dataType): ${list.length}");
      return list;
    } catch (e) {
      debugPrint("GET GENERICS CRITICAL ERROR: $dataType -> $e");
      return [];
    }
  }
}
