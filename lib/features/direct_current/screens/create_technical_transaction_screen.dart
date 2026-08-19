import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/models/direct_current_item.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';

class CreateTechnicalTransactionScreen extends StatefulWidget {
  final DirectCurrentItem data;
  const CreateTechnicalTransactionScreen({super.key, required this.data});

  @override
  State<CreateTechnicalTransactionScreen> createState() => _CreateTechnicalTransactionScreenState();
}

class _CreateTechnicalTransactionScreenState extends State<CreateTechnicalTransactionScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, String>> _types = [];
  String? _selectedCode;
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await DirectCurrentService.getTransactionTypes();
      if (mounted) {
        setState(() {
          _types = types;
          if (_types.isNotEmpty) {
            _selectedCode = _types.first['id'];
            _selectedName = _types.first['name'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار نوع المعاملة"), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. إرسال المعاملة الفعلية للسيرفر (InsertProccess)
      final result = await DirectCurrentService.insertProcess(
        meterNum: widget.data.mtrMNum,
        procCode: _selectedCode!,
        procName: _selectedName!,
        notes: _notesController.text.trim(),
      );

      // 2. تحديث حالة المعاملة في النظام الجديد (اختياري حسب الحاجة)
      final prefs = await SharedPreferences.getInstance();
      final empNo = prefs.getString('EMP_NO') ?? '';
      await DirectCurrentService.processDirectCurrent(widget.data.id, empNo);

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.contains("تم") || result.contains("نجاح") || result.toLowerCase().contains("success")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المعاملة بنجاح'), backgroundColor: AppTheme.accentGreen),
          );
          Navigator.pop(context, true); // العودة بنجاح
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('النتيجة من السيرفر: $result'), backgroundColor: AppTheme.accentRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الإرسال: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: AppBar(
          title: const Text('إنشاء معاملة فنية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 30),

                  const Text('نوع المعاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  _buildDropdown(),

                  const SizedBox(height: 25),
                  const Text('ملاحظات المعاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  _buildNotesField(),

                  const SizedBox(height: 50),
                  _buildSubmitButton(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'المشترك:', widget.data.cusmName),
          const Divider(height: 20),
          _infoRow(Icons.electric_meter_outlined, 'رقم العداد:', widget.data.mtrMNum),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCode,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryBlue),
          hint: const Text("اختر نوع المعاملة..."),
          items: _types.map((type) => DropdownMenuItem(
            value: type['id'],
            child: Text(type['name'] ?? ""),
          )).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCode = val;
              _selectedName = _types.firstWhere((t) => t['id'] == val)['name'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'اكتب تفاصيل المعاملة هنا...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.secondaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
      ),
      child: _isSaving 
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text('تأكيد وإرسال المعاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}
