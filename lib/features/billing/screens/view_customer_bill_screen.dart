
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              // Circular Logo - Matching HomeScreen
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
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
          const SizedBox(height: 15),
          const Text(
            'إستعراض الفواتير',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue.withOpacity(0.9), AppTheme.secondaryBlue.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'المجموع المطلوب: ',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: '$_sumRequired دينار',
                style: const TextStyle(
                  color: Color(0xFF06F106),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableBillCard(BillingItem bill) {
    bool isUnpaid = bill.payFlag == "0";
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primaryBlue,
          collapsedIconColor: AppTheme.textGrey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            'فاتورة شهر : ${bill.bilIssuYm}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
          ),
          trailing: Text(
            bill.bilRemain,
            style: TextStyle(
              color: isUnpaid ? const Color(0xFF06F106) : AppTheme.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 15),
                  _detailRow(Icons.account_balance_wallet_outlined, 'القيمة الكلية', bill.bilTot),
                  _detailRow(Icons.speed_rounded, 'كمية الاستهلاك', '${bill.bilQty} (ك.و)'),
                  _detailRow(Icons.calendar_today_rounded, 'تاريخ الفاتورة', bill.bilBilDate),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textGrey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }
}
