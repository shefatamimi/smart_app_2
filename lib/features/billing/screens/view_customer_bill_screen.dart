import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:smart_application/features/billing/services/billing_service.dart';
import 'package:smart_application/features/billing/models/billing_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class ViewCustomerBillScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const ViewCustomerBillScreen({super.key, required this.meterInfo});

  @override
  State<ViewCustomerBillScreen> createState() => _ViewCustomerBillScreenState();
}

class _ViewCustomerBillScreenState extends State<ViewCustomerBillScreen> {
  List<BillingItem> _bills = [];
  bool _isLoading = false;
  double _sumRequired = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    final cityId = widget.meterInfo['MTR_CITY'] ?? "";
    final subNum = widget.meterInfo['MTR_NUM'] ?? "";
    
    final results = await BillingService.getMeterInvoices(cityId, subNum);
    
    // منطق CalcSum من الجافا مع فلترة القائمة
    double sum = 0.0;
    List<BillingItem> unpaidBills = [];
    
    for (var bill in results) {
      if (bill.payFlag == "0") {
        double remain = double.tryParse(bill.bilRemain) ?? 0.0;
        sum += remain;
        sum = double.parse(sum.toStringAsFixed(3));
      }
    }

    if (mounted) {
      setState(() {
        // نُظهر جميع الفواتير (السجل الكامل) كما كان سابقاً
        _bills = results;
        _sumRequired = sum;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWhite,
        body: Column(
          children: [
            // --- Header (Logo + Title) matching the image exactly ---
            _buildHeader(),

            // --- Summary Bar (المطلوب) matching the image exactly ---
            if (!_isLoading) _buildSummaryBar(),

            // --- Expandable List ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryBlue))
                  : _bills.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _bills.length,
                          itemBuilder: (ctx, index) => _buildExpandableBillCard(_bills[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: AppTheme.accentGreen.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد فواتير مستحقة حالياً',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'تم تسديد كافة الذمم المطلوبة',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                height: 65,
                width: 65,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('lib/assets/images.jpg', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'إستعراض الفواتير',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Text(
          'المطلوب : $_sumRequired دينار',
          style: const TextStyle(color: Color(0xFF06F106), fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildExpandableBillCard(BillingItem bill) {
    bool isUnpaid = bill.payFlag == "0";
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey,
          title: Text(
            'فاتورة شهر : ${bill.bilIssuYm}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87),
          ),
          trailing: Text(
            bill.bilRemain,
            style: TextStyle(
              color: isUnpaid ? const Color(0xFF06F106) : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  _detailRow('القيمة الكلية', bill.bilTot),
                  _detailRow('كمية الاستهلاك', '${bill.bilQty} (ك.و)'),
                  _detailRow('تاريخ الفاتورة', bill.bilBilDate),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }
}
