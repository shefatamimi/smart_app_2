class DirectCurrentItem {
  String id = "";
  String mpid = "";
  String entryEmpNo = "";
  String cusmCity = "";
  String cusmNum = "";
  String engApproved = "";
  String empAnswer = "";
  String mtrPhase = "";
  String mtrIsSmart = "";
  String unpaidBillAmt = "";
  String state = "";
  String entryDate = "";
  String entryTime = "";
  String engEmpNo = "";
  String cusmName = "";
  String mtrMNum = "";
  String mtrLocation = "";
  String regionDesc = "";
  String readerMobile = "";
  String engName = "";
  String engNotes = "";
  String empNotes = "";
  String stateDesc = "";
  String wrkName = "";

  DirectCurrentItem();

  // تحويل من خريطة بيانات (XML/JSON) إلى كائن بمرونة عالية
  DirectCurrentItem.fromMap(Map<String, String> map) {
    // دالة مساعدة للبحث عن المفتاح بغض النظر عن حالة الأحرف
    String f(String key) => map[key] ?? map[key.toUpperCase()] ?? map[key.toLowerCase()] ?? "";

    id = f('ID');
    mpid = f('MPID');
    entryEmpNo = f('ENTRY_EMP_NO');
    cusmCity = f('CUSM_CITY');
    cusmNum = f('CUSM_NUM');
    engApproved = f('ENG_APPROVED');
    empAnswer = f('EMP_ANSWER');
    mtrPhase = f('MTR_PHASE');
    mtrIsSmart = f('MTR_IS_SMART');
    unpaidBillAmt = f('UNPAID_BILL_AMT');
    state = f('STATE');
    entryDate = f('ENTRY_DATE');
    entryTime = f('ENTRY_TIME');
    engEmpNo = f('ENG_EMP_NO');
    cusmName = f('CUSM_NAME');
    mtrMNum = f('MTR_M_NUM');
    mtrLocation = f('MTR_LOCATION');
    regionDesc = f('REGION_DESC');
    readerMobile = f('READER_MOBILE');
    engName = f('ENG_NAME');
    engNotes = f('ENG_NOTES');
    empNotes = f('EMP_NOTES');
    wrkName = f('WRK_NAME');

    // منطق وصف الحالة كما في الجافا
    if (state == "1") {
      stateDesc = "بانتظار إجراء المهندس";
    } else if (state == "2") {
      stateDesc = "بانتظار إجراء المقدم";
    } else if (state == "3") {
      stateDesc = "منتهية";
    } else {
      stateDesc = "غير معروف";
    }
  }

  String get engApprovedDesc {
    if (engApproved == "1") return "مقبول";
    if (engApproved == "0") return "مرفوض";
    return "بدون إجراء";
  }
}
