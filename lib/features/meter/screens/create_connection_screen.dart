import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class CreateConnectionScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const CreateConnectionScreen({super.key, required this.meterInfo});

  @override
  State<CreateConnectionScreen> createState() => _CreateConnectionScreenState();
}

class _CreateConnectionScreenState extends State<CreateConnectionScreen> {
  bool _isProcessing = false;

  void _handleConnection() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد العملية', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('سيتم إدخال حركة وصل على الإشتراك، هل ترغب بالمتابعة ؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryBlue, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _executeConnTrans();
              },
              child: const Text('نعم، متابعة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeConnTrans() async {
    setState(() => _isProcessing = true);
    
    // جلب البيانات المطلوبة (التي كانت تُجلب من SharedPreferences في الجافا)
    // ملاحظة: هنا نستخدم قيم افتراضية حالياً كما في كود الجافا
    final result = await DirectCurrentService.connTrans(
      meterNum: widget.meterInfo['display_meter'] ?? "",
      workshopId: "1", // SYS_MINOR
      workshopName: "ورشة الطوارئ", // SYS_DESC
      userName: "ADMIN", // ORACLE_USER
      cityId: widget.meterInfo['MTR_CITY'] ?? "",
      custId: widget.meterInfo['MTR_NUM'] ?? "",
      lat: 0.0,
      lng: 0.0,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      _showResult(result);
    }
  }

  void _showResult(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: msg.contains("نجاح") ? AppTheme.accentGreen : AppTheme.accentRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: AppBar(
          title: const Text('إنشاء حركة وصل'),
          backgroundColor: AppTheme.secondaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('رقم العداد', widget.meterInfo['display_meter'] ?? '---'),
                      _buildInfoRow('اسم المشترك', widget.meterInfo['display_name'] ?? '---'),
                      _buildInfoRow('هاتف المشترك', widget.meterInfo['CUSM_TELEPHONE'] ?? '---'),
                      _buildInfoRow('عنوان المشترك', widget.meterInfo['display_area'] ?? '---'),
                      _buildInfoRow('نوع الفصل', widget.meterInfo['SEP_TYPE_DESC'] ?? '---'),
                      _buildInfoRow('تاريخ الفصل', widget.meterInfo['SEP_DATE'] ?? '---'),
                      _buildInfoRow('الحالة', widget.meterInfo['STATUS_DESC'] ?? '---'),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: AppTheme.surfaceWhite,
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleConnection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isProcessing 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('إنشاء حركة وصل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
