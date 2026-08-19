class BillingItem {
  final String bilNum, bilIssuYm, bilQty, bilAmt, bilTot, bilPayTot, bilRemain, bilLpayDate, bilBilDate, payFlag;

  BillingItem({
    required this.bilNum, required this.bilIssuYm, required this.bilQty,
    required this.bilAmt, required this.bilTot, required this.bilPayTot,
    required this.bilRemain, required this.bilLpayDate, required this.bilBilDate,
    required this.payFlag,
  });

  factory BillingItem.fromMap(Map<String, String> map) {
    // دالة مساعدة للبحث في الخريطة بغض النظر عن حالة الأحرف
    String find(String key) {
      return map[key] ?? map[key.toUpperCase()] ?? map[key.toLowerCase()] ?? "";
    }

    return BillingItem(
      bilNum: find('BIL_NUM'),
      bilIssuYm: find('BIL_ISSU_YM'),
      bilQty: find('BIL_QTY'),
      bilAmt: find('BIL_AMT'),
      bilTot: find('BIL_TOT'),
      bilPayTot: find('BIL_PAY_TOT'),
      bilRemain: find('BIL_REMAIN').isEmpty ? "0.0" : find('BIL_REMAIN'),
      bilLpayDate: find('BIL_LPAY_DATE'),
      bilBilDate: find('BIL_BIL_DATE'),
      payFlag: find('PAYFLAG').isEmpty ? find('PAY_FLAG') : find('PAYFLAG'),
    );
  }
}
