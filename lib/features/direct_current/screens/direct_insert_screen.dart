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
  bool _isSending = false;
  bool _isLoadingData = true;

  List<Map<String, String>> _engineers = [];
  List<Map<String, String>> _reasons = [];
  String? _selectedEngineerId;
  String? _selectedEngineerName;
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final engs = await DirectCurrentService.getEngineers();
      final reas = await DirectCurrentService.getDirectReasons();
      if (mounted) {
        setState(() {
          _engineers = engs;
          _reasons = reas;
          if (_engineers.isNotEmpty) {
             _selectedEngineerId = _engineers.first['id'];
             _selectedEngineerName = _engineers.first['name']?.split(' - ').first;
          }
          if (_reasons.isNotEmpty) _selectedReason = _reasons.first['name'];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedEngineerId == null || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المهندس والسبب')));
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
        'ENG_WRKSHP_NO': _selectedEngineerId ?? '0',
        'ENG_NAME': _selectedEngineerName ?? '',
        'EMP_NOTES': '$_selectedReason ${_noteController.text}'.trim(),
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
        body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoTile('المشترك', widget.meterInfo['display_name'] ?? ''),
              _buildInfoTile('رقم العداد', widget.meterInfo['display_meter'] ?? ''),
              const Divider(height: 40),
              
              const Text('المهندس المسؤول', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _engineers.any((e) => e['id'] == _selectedEngineerId) ? _selectedEngineerId : null,
                    isExpanded: true,
                    hint: const Text("اختر المهندس"),
                    items: _engineers.map((e) => DropdownMenuItem(
                      value: e['id'],
                      child: Text(e['name'] ?? ""),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedEngineerId = val;
                        _selectedEngineerName = _engineers.firstWhere((e) => e['id'] == val)['name']?.split(' - ').first;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('سبب التأمين', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _reasons.any((r) => r['name'] == _selectedReason) ? _selectedReason : null,
                    isExpanded: true,
                    hint: const Text("اختر السبب"),
                    items: _reasons.map((r) => DropdownMenuItem(
                      value: r['name'],
                      child: Text(r['name'] ?? ""),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب أي ملاحظات إضافية هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppTheme.backgroundGrey,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending || _engineers.isEmpty ? null : _handleSubmit,
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
