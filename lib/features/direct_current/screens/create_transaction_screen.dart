import 'package:flutter/material.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';

class CreateTransactionScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const CreateTransactionScreen({super.key, required this.meterInfo});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
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
      final meterNum = widget.meterInfo['display_meter'] ?? "";
      
      final result = await DirectCurrentService.insertProcess(
        meterNum: meterNum,
        procCode: _selectedCode!,
        procName: _selectedName!,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.contains("تم") || result.contains("نجاح") || result.toLowerCase().contains("success")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المعاملة بنجاح'), backgroundColor: AppTheme.accentGreen),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('النتيجة: $result'), backgroundColor: AppTheme.accentRed),
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
          title: const Text('إنشاء معاملة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMeterInfo(),
                  const SizedBox(height: 30),
                  const Text('نوع المعاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildDropdown(),
                  const SizedBox(height: 25),
                  const Text('الملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'اكتب ملاحظات المعاملة هنا...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تأكيد وإرسال المعاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMeterInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _infoRow(Icons.person, 'المشترك:', widget.meterInfo['display_name'] ?? ""),
          const Divider(height: 20),
          _infoRow(Icons.electric_meter, 'رقم العداد:', widget.meterInfo['display_meter'] ?? ""),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCode,
          isExpanded: true,
          alignment: Alignment.centerRight,
          hint: const Align(
            alignment: Alignment.centerRight,
            child: Text("اختر النوع..."),
          ),
          items: _types.map((t) => DropdownMenuItem(
            value: t['id'], 
            alignment: Alignment.centerRight,
            child: Text(t['name'] ?? "", textAlign: TextAlign.right),
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
}
