class TechnicalTransactionItem {
  final String id;
  final String userId;
  final String opTypeCode;
  final String mtrNum;
  final String entryDate;
  final String opTypeDesc;
  final String notes;
  final String workshopId;
  final String lat;
  final String lng;

  TechnicalTransactionItem({
    required this.id,
    required this.userId,
    required this.opTypeCode,
    required this.mtrNum,
    required this.entryDate,
    required this.opTypeDesc,
    required this.notes,
    required this.workshopId,
    required this.lat,
    required this.lng,
  });

  factory TechnicalTransactionItem.fromMap(Map<String, String> map) {
    String f(String key) => map[key] ?? map[key.toUpperCase()] ?? map[key.toLowerCase()] ?? "";

    return TechnicalTransactionItem(
      id: f('ID'),
      userId: f('User_ID'),
      opTypeCode: f('OP_TYPE_CODE'),
      mtrNum: f('MTR_NUM'),
      entryDate: f('ENTRY_DATE'),
      opTypeDesc: f('OP_TYPE_TEXT'),
      notes: f('NOTE'),
      workshopId: f('WRKSHP_ID'),
      lat: f('X_LAT'),
      lng: f('Y_LONG'),
    );
  }
}
