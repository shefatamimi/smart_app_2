import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/features/direct_current/models/dconn_trans_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class ConnectionInquiryScreen extends StatefulWidget {
  const ConnectionInquiryScreen({super.key});

  @override
  State<ConnectionInquiryScreen> createState() => _ConnectionInquiryScreenState();
}

class _ConnectionInquiryScreenState extends State<ConnectionInquiryScreen> {
  DateTime selectedDate = DateTime.now();
  List<DconnTransItem> _transactions = [];
  bool _isLoading = false;

  Future<void> _handleSearch() async {
    final prefs = await SharedPreferences.getInstance();
    
    // التحقق من الإعدادات كما في كود الجافا
    String oracleUser = prefs.getString('ORACLE_USER') ?? "0";
    String workshopId = prefs.getString('SYS_MINOR') ?? "0";

    if (oracleUser == "0" || oracleUser.isEmpty) {
      _showSnackBar("لا يوجد رقم مستخدم لغايات الفصل و الوصل", AppTheme.accentRed);
      return;
    }
    if (workshopId == "0" || workshopId.isEmpty) {
      _showSnackBar("لا يوجد رقم ورشة", AppTheme.accentRed);
      return;
    }

    setState(() => _isLoading = true);
    
    final results = await DirectCurrentService.getDisconnTransactions(
      date: selectedDate,
      workshopId: workshopId,
    );
    
    if (mounted) {
      setState(() {
        _transactions = results;
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: Column(
          children: [
            _buildHeader(),
            _buildDateSelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryBlue))
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (ctx, index) => _buildTransactionCard(_transactions[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
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
              const Text(
                'إستعلام حركات وصل',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("تاريخ الحركة", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('إستعلام الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(DconnTransItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // عند النقر يتم إرجاع رقم العداد أو الاشتراك للشاشة السابقة كما في الجافا
            Navigator.pop(context, item.mtrMNum);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.electric_meter, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text("رقم العداد: ${item.mtrMNum}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Text(item.connDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(),
                _buildInfoRow(Icons.numbers, "رقم الإشتراك", item.subscriptionNumber),
                _buildInfoRow(Icons.person, "المشترك", item.cusmName),
                _buildInfoRow(Icons.calendar_month, "تاريخ الحركة", item.connDate),
                _buildInfoRow(Icons.category, "نوع الحركة", item.dconnKind.isEmpty ? "غير محدد" : item.dconnKind),
                _buildInfoRow(Icons.payments_outlined, "حالة الدفع", item.state.isEmpty ? "غير متوفر" : item.state),
                _buildInfoRow(Icons.engineering, "الورشة", item.workshopName),
                if (item.notes.isNotEmpty && item.notes != "---")
                  _buildInfoRow(Icons.note, "ملاحظات", item.notes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('لا توجد حركات مسجلة لهذا التاريخ', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
