import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/features/direct_current/models/technical_transaction_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class TechnicalInquiryScreen extends StatefulWidget {
  const TechnicalInquiryScreen({super.key});

  @override
  State<TechnicalInquiryScreen> createState() => _TechnicalInquiryScreenState();
}

class _TechnicalInquiryScreenState extends State<TechnicalInquiryScreen> {
  DateTime selectedDate = DateTime.now();
  List<TechnicalTransactionItem> _transactions = [];
  bool _isLoading = false;

  Future<void> _handleSearch() async {
    final prefs = await SharedPreferences.getInstance();
    String workshopId = prefs.getString('SYS_MINOR') ?? "0";

    if (workshopId == "0" || workshopId.isEmpty) {
      _showSnackBar("لا يوجد رقم ورشة", AppTheme.accentRed);
      return;
    }

    setState(() => _isLoading = true);
    
    final results = await DirectCurrentService.getTechnicalTransactions(
      date: selectedDate,
      workshopId: workshopId,
    );
    
    if (mounted) {
      setState(() {
        _transactions = results;
        _isLoading = false;
      });
      if (results.isEmpty) {
        _showSnackBar("لا يوجد معاملات لهذا التاريخ", AppTheme.accentOrange);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: color),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'إستعلام معاملات',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 40),
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
          const Text("تاريخ الإضافة", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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

  Widget _buildTransactionCard(TechnicalTransactionItem item) {
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
            // إرجاع رقم العداد للشاشة الرئيسية للبحث عنه
            Navigator.pop(context, item.mtrNum);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.opTypeDesc,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Text(item.entryDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const Divider(),
                _buildInfoRow(Icons.electric_meter, "رقم العداد", item.mtrNum),
                if (item.notes.isNotEmpty && item.notes != "anyType{}")
                  _buildInfoRow(Icons.note_alt_outlined, "الملاحظات", item.notes),
                _buildInfoRow(Icons.person_outline, "رقم المستخدم", item.userId),
                if (item.lat.isNotEmpty && item.lat != "0")
                  _buildInfoRow(Icons.location_on_outlined, "الموقع", "${item.lat}, ${item.lng}"),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('لا توجد معاملات مسجلة', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
