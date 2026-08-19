class SyncDataItem {
  String meterNum = "";
  String workshopId = "";
  String workshopName = "";
  String cityNum = "";
  String subNum = "";
  String type = ""; // حركة وصل / حركة فصل
  String state = ""; // غير مرحلة
  String rawData = ""; // النص الأصلي قبل التشفير

  SyncDataItem();

  Map<String, dynamic> toJson() => {
    'MeterNum': meterNum,
    'WorkShopId': workshopId,
    'WorkShopName': workshopName,
    'CityNum': cityNum,
    'SubNum': subNum,
    'Type': type,
    'State': state,
    'RawData': rawData,
  };
}
