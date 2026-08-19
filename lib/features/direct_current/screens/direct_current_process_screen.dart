import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/direct_current/models/direct_current_item.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';

import 'package:smart_application/features/direct_current/screens/create_technical_transaction_screen.dart';

class DirectCurrentProcessScreen extends StatefulWidget {
  final DirectCurrentItem data;
  const DirectCurrentProcessScreen({super.key, required this.data});

  @override
  State<DirectCurrentProcessScreen> createState() => _DirectCurrentProcessScreenState();
}

class _DirectCurrentProcessScreenState extends State<DirectCurrentProcessScreen> {
  bool _isProcessing = false;

  Future<void> _handleProcessTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTechnicalTransactionScreen(data: widget.data),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // إغلاق هذه الشاشة أيضاً لتحديث القائمة الرئيسية
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProcess = widget.data.state == "2"; // حالة "بانتظار المقدم" تعني جاهزية الإنشاء

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        bottomNavigationBar: canProcess ? _buildBottomAction() : null,
        body: CustomScrollView(
          slivers: [
            // ... (بقية الكود كما هو)
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text('تفاصيل المعاملة الفنية', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -50,
                        top: -50,
                        child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05)),
                      ),
                      Center(
                        child: Icon(Icons.description_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- Status Badge ---
                  _buildStatusHeader(widget.data),

                  const SizedBox(height: 20),

                  // --- Sections ---
                  _buildElegantSection('معلومات المشترك', Icons.person_outline_rounded, [
                    _buildDataRow(Icons.numbers_rounded, 'رقم العداد', widget.data.mtrMNum),
                    _buildDataRow(Icons.person_pin_rounded, 'اسم المشترك', widget.data.cusmName),
                    _buildDataRow(Icons.location_on_outlined, 'المنطقة', widget.data.regionDesc),
                    _buildDataRow(Icons.map_outlined, 'رقم الاشتراك', "${widget.data.cusmCity}/${widget.data.cusmNum}"),
                  ]),

                  const SizedBox(height: 16),

                  _buildElegantSection('الحالة الفنية والمالية', Icons.bolt_rounded, [
                    _buildDataRow(Icons.memory_rounded, 'نوع العداد', widget.data.mtrIsSmart == "1" ? "عداد ذكي" : "عداد عادي"),
                    _buildDataRow(Icons.electrical_services_rounded, 'المرحلة (Phase)', "${widget.data.mtrPhase} فاز"),
                    _buildDataRow(Icons.payments_outlined, 'الذمم المتبقية', "${widget.data.unpaidBillAmt} دينار"),
                    _buildDataRow(Icons.calendar_month_rounded, 'تاريخ الإدخال', widget.data.entryDate),
                  ]),

                  const SizedBox(height: 16),

                  _buildElegantSection('إجراءات وملاحظات', Icons.assignment_turned_in_outlined, [
                    _buildDataRow(Icons.engineering_rounded, 'المهندس المسؤول', widget.data.engName),
                    _buildDataRow(Icons.check_circle_outline_rounded, 'حالة القبول', widget.data.engApprovedDesc),
                    _buildDataRow(Icons.speaker_notes_outlined, 'ملاحظات الموظف', widget.data.empNotes),
                    _buildDataRow(Icons.edit_note_rounded, 'ملاحظات المهندس', widget.data.engNotes.isEmpty ? "لا يوجد ملاحظات" : widget.data.engNotes),
                  ]),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleProcessTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isProcessing 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('إنشاء المعاملة الفنية الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusHeader(DirectCurrentItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('حالة المعاملة الحالية:', 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(item.stateDesc, 
              style: const TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantSection(String title, IconData icon, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppTheme.textGrey),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
