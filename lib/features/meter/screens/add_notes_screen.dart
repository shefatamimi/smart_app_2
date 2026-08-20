import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';

class AddNotesScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const AddNotesScreen({super.key, required this.meterInfo});

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, String>> _noteTypes = [];
  String? _selectedTypeId;
  String? _selectedTypeName;

  @override
  void initState() {
    super.initState();
    _loadNoteTypes();
  }

  Future<void> _loadNoteTypes() async {
    try {
      final types = await DirectCurrentService.getNoteTypes();
      if (mounted) {
        setState(() {
          _noteTypes = types;
          if (_noteTypes.isNotEmpty) {
            _selectedTypeId = _noteTypes.first['id'];
            _selectedTypeName = _noteTypes.first['name'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('خطأ في جلب أنواع الملاحظات: $e', isError: true);
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedTypeId == null || _selectedTypeId == "0") {
      _showSnackBar('يرجى اختيار نوع الملاحظة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final empNo = prefs.getString('EMP_NO') ?? "";
      final empName = prefs.getString('ORACLE_USER') ?? "";
      final meter = widget.meterInfo['display_meter'] ?? "";

      final result = await DirectCurrentService.updateSimMngMaster(
        id: 0,
        status: int.parse(_selectedTypeId!),
        empNo: empNo,
        empName: empName,
        meter: meter,
        type: 16,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result == "1") {
          _showSnackBar('تم إرسال الملاحظة بنجاح');
          Navigator.pop(context);
        } else {
          _showSnackBar('حدث خطأ، لم يتم إرسال الملاحظة', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('خطأ أثناء الإرسال: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? AppTheme.accentRed : AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: AppBar(
          title: const Text('فاقد الاتصال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMeterCard(),
                    const SizedBox(height: 30),
                    const Text('نوع الملاحظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    _buildDropdown(),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('تأكيد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppTheme.textGrey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMeterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.electric_meter, 'رقم العداد', widget.meterInfo['display_meter'] ?? '---'),
          const Divider(height: 25),
          _buildInfoRow(Icons.person, 'المشترك', widget.meterInfo['display_name'] ?? '---'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryBlue),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark), textAlign: TextAlign.left)),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTypeId,
          isExpanded: true,
          hint: const Text('اختر نوع الملاحظة'),
          items: _noteTypes.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'] ?? ""))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedTypeId = val;
              _selectedTypeName = _noteTypes.firstWhere((t) => t['id'] == val)['name'];
            });
          },
        ),
      ),
    );
  }
}
