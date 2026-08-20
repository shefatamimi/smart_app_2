class DconnTransItem {
  final String mtrMNum;
  final String cusmName;
  final String connDate;
  final String connTime;
  final String status;
  final String workshopName;
  final String notes;
  
  // حقول إضافية من كود Java الأصلي
  final String dconnCity;
  final String dconnNum;
  final String dconnKind;
  final String state;
  final String id;

  DconnTransItem({
    required this.mtrMNum,
    required this.cusmName,
    required this.connDate,
    required this.connTime,
    required this.status,
    required this.workshopName,
    required this.notes,
    required this.dconnCity,
    required this.dconnNum,
    required this.dconnKind,
    required this.state,
    required this.id,
  });

  /// الحصول على رقم الاشتراك المنسق (City-Number)
  String get subscriptionNumber => 
      (dconnCity.isEmpty || dconnNum.isEmpty) ? "---" : "${dconnCity.padLeft(3, '0')}-${dconnNum.padLeft(7, '0')}";

  factory DconnTransItem.fromMap(Map<String, String> map) {
    // دالة مساعدة للبحث عن المفاتيح بغض النظر عن حالة الأحرف
    String f(String key) => map[key] ?? map[key.toUpperCase()] ?? map[key.toLowerCase()] ?? "";

    // استخراج التاريخ بمرونة (Java uses DCONN_DATE)
    String dateVal = f('DCONN_CONN_DATE_STR');
    if (dateVal.isEmpty) dateVal = f('DCONN_CONN_DATE');
    if (dateVal.isEmpty) dateVal = f('DCONN_DATE');

    return DconnTransItem(
      mtrMNum: f('MTR_M_NUM').isEmpty ? f('ID') : f('MTR_M_NUM'),
      cusmName: f('CUSM_NAME'),
      connDate: dateVal,
      connTime: f('DCONN_CONN_TIME'),
      status: f('STATUS_DESC'),
      workshopName: f('WRK_NAME').isEmpty ? f('DCONN_TECN_NAME') : f('WRK_NAME'),
      notes: f('DCONN_NOTES'),
      dconnCity: f('DCONN_CITY'),
      dconnNum: f('DCONN_NUM'),
      dconnKind: f('DCONN_KIND'),
      state: f('STATE'),
      id: f('ID'),
    );
  }
}
