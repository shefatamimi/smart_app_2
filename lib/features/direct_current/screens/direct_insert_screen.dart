import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class DirectInsertScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const DirectInsertScreen({super.key, required this.meterInfo});

  @override
  State<DirectInsertScreen> createState() => _DirectInsertScreenState();
}

class _DirectInsertScreenState extends State<DirectInsertScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _workshopController = TextEditingController();
  bool _isSending = false;

  Future<void> _handleSubmit() async {
    if (_workshopController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم الورشة')));
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final empNo = prefs.getString('EMP_NO') ?? '0';

      // تجهيز البيانات بنفس منطق الجافا
      final params = {
        'ENTRY_EMP_NO': empNo,
        'CUSM_CITY': widget.meterInfo['MTR_CITY'] ?? '',
        'CUSM_NUM': widget.meterInfo['MTR_NUM'] ?? '',
        'CUSM_NAME': (widget.meterInfo['display_name'] ?? '').replaceAll('إسم المشترك: ', '').trim(),
        'MTR_M_NUM': widget.meterInfo['display_meter'] ?? '',
        'MTR_PHASE': (widget.meterInfo['display_faz'] ?? '').replaceAll('فاز', '').trim(),
        'MTR_IS_SMART': widget.meterInfo['display_smart'] == 'ذكي' ? 1 : 0,
        'MTR_LOCATION': '0.0,0.0',
        'UNPAID_BILL_AMT': double.tryParse((widget.meterInfo['display_inv_amt'] ?? '0').replaceAll(RegExp(r'[^0-9.]'), ''))?.toInt() ?? 0,
        'REGION_DESC': (widget.meterInfo['display_area'] ?? '').replaceAll('رقم المنطقة:', '').trim(),
        'READER_MOBILE': (widget.meterInfo['display_mobile'] ?? '').replaceAll('هاتف القارئ:', '').trim(),
        'ENG_WRKSHP_NO': _workshopController.text.trim(),
        'ENG_NAME': 'ورشة الطوارئ',
        'EMP_NOTES': _noteController.text.trim(),
      };

      final result = await DirectCurrentService.insertDirectCurrent(params);

      if (!mounted) return;
      setState(() => _isSending = false);

      if (result == -2) {
        _showResultDialog('تنبيه', 'معاملة مكررة لهذا اليوم', AppTheme.accentOrange);
      } else if (result > 0) {
        _showResultDialog('نجاح', 'تم إرسال المعاملة بنجاح', AppTheme.accentGreen, isSuccess: true);
      } else {
        _showResultDialog('فشل', 'فشل في إرسال المعاملة، حاول لاحقاً', AppTheme.accentRed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showResultDialog('خطأ', 'حدث خطأ: $e', AppTheme.accentRed);
      }
    }
  }

  void _showResultDialog(String title, String msg, Color color, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isSuccess) Navigator.pop(context);
            },
            child: const Text('حسناً'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدخال حركة تأمين تيار'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoTile('المشترك', widget.meterInfo['display_name'] ?? ''),
              _buildInfoTile('رقم العداد', widget.meterInfo['display_meter'] ?? ''),
              const Divider(height: 40),
              const Text('رقم الورشة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _workshopController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم الورشة هنا',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.backgroundGrey,
                ),
              ),
              const SizedBox(height: 20),
              const Text('ملاحظات الموظف', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب أي ملاحظات إضافية هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.backgroundGrey,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إرسال المعاملة الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textGrey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
