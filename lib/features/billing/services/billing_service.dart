import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:smart_application/core/api_client.dart';
import 'package:smart_application/core/app_constants.dart';
import 'package:smart_application/features/billing/models/billing_item.dart';

class BillingService {
  static Future<List<BillingItem>> getMeterInvoices(String cityId, String subNum) async {
    try {
      // ضمان التنسيق: CityId (3 خانات) و SubNum (7 خانات) كما في الجافا
      String paddedCityId = cityId.trim().padLeft(3, '0');
      String paddedSubNum = subNum.trim().padLeft(7, '0');
      String query = "DataType:9,CityId:$paddedCityId,SubNum:$paddedSubNum";
      
      debugPrint(">>> BILLING PLAIN DATA: $query");
      String response = await ApiClient.makeSoapRequest(
        AppConstants.baseUrl, 
        "GetInvoicesInfoEnc", 
        ApiClient.encryptRSA(query)
      );
      
      final document = xml.XmlDocument.parse(response);
      
      // الوصول لـ NewDataSet (تجاوز الـ schema و diffgram)
      final newDataSet = document.findAllElements('NewDataSet').firstOrNull;
      
      final rows = newDataSet != null 
          ? newDataSet.children.whereType<xml.XmlElement>()
          : document.descendants.whereType<xml.XmlElement>().where((e) => e.findElements('BIL_NUM').isNotEmpty);
      
      List<BillingItem> list = [];
      for (var row in rows) {
        Map<String, String> data = {};
        for (var child in row.children.whereType<xml.XmlElement>()) {
          data[child.name.local] = child.innerText.trim();
        }
        
        if (data.isNotEmpty) {
          list.add(BillingItem.fromMap(data));
        }
      }
      return list;
    } catch (e) {
      debugPrint("BILLING ERROR: $e");
      return [];
    }
  }
}
