class MeterEventItem {
  String meterNo = "";
  String commAddr = "";
  String dateTime = "";
  String eventDesc = "";

  MeterEventItem({
    required this.meterNo,
    required this.commAddr,
    required this.dateTime,
    required this.eventDesc,
  });

  factory MeterEventItem.fromMap(Map<String, String> map) {
    return MeterEventItem(
      meterNo: map['METER_NO'] ?? "",
      commAddr: map['COMMADDR'] ?? "",
      dateTime: map['DATE_TIME'] ?? "",
      eventDesc: (map['LOCAL_LANGUAGE_DESC'] ?? "").replaceAll("  ", " ").trim(),
    );
  }
}
