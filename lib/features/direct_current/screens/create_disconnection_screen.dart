import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';

class CreateDisconnectionScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const CreateDisconnectionScreen({super.key, required this.meterInfo});

  @override
  State<CreateDisconnectionScreen> createState() => _CreateDisconnectionScreenState();
}

class _CreateDisconnectionScreenState extends State<CreateDisconnectionScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingLists = true;

  String? _selectedKind;
  String? _selectedReason;

  List<Map<String, String>> _kinds = [];
  List<Map<String, String>> _reasons = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      // جلب البيانات من السيرفر باستخدام الدوال المتخصصة الجديدة التي أضفناها
      final reasons = await DirectCurrentService.getDisconnectionReasons();
      final kinds = await DirectCurrentService.getDisconnectionKinds();

      if (mounted) {
        if (reasons.isEmpty && kinds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("لم يتم العثور على بيانات في السيرفر (الرد فارغ)"),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() {
          _kinds = kinds;
          _reasons = reasons;
          
          if (_kinds.isNotEmpty) _selectedKind = _kinds.first['id'];
          if (_reasons.isNotEmpty) _selectedReason = _reasons.first['id'];
          
          _isLoadingLists = false;
        });
      }
    } catch (e) {
      debugPrint(">>> LOAD DROPDOWN ERROR: $e");
      if (mounted) {
        setState(() => _isLoadingLists = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في الاتصال: $e"), backgroundColor: AppTheme.accentRed),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedKind == null || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار النوع والسبب"), backgroundColor: AppTheme.accentRed),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إرسال الحركة للسيرفر (مع قيم موقع افتراضية حالياً أو جلبها عبر مكتبة geolocator)
      final result = await DirectCurrentService.disConnTrans(
        meterNum: widget.meterInfo['display_meter'] ?? "",
        workshopId: prefs.getString('SYS_MINOR') ?? "0",
        workshopName: prefs.getString('SYS_DESC') ?? "",
        userName: prefs.getString('ORACLE_USER') ?? "",
        cityId: widget.meterInfo['MTR_CITY'] ?? "",
        custId: widget.meterInfo['MTR_NUM'] ?? "",
        kind: _selectedKind!,
        reason: _selectedReason!,
        notes: _notesController.text.trim(),
        lat: 32.556, // مثال: إحداثيات إربد
        lng: 35.845,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        
        if (result.contains("نجاح") || result.contains("تم")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تمت العملية بنجاح", textAlign: TextAlign.right), backgroundColor: AppTheme.accentGreen),
          );
          Navigator.pop(context);
        } else {
          _showOfflineSaveDialog(
            "strMTR_NUM:${widget.meterInfo['display_meter']},intWorkshopID:${prefs.getString('SYS_MINOR')},strWorkshopName:${prefs.getString('SYS_DESC')},strOraUserName:${prefs.getString('ORACLE_USER')},CityId:${widget.meterInfo['MTR_CITY']},CustId:${widget.meterInfo['MTR_NUM']},DisconnKind:$_selectedKind,DisconnReason:$_selectedReason,strDisconnReson:${_notesController.text.trim()},Lat:32.556,Lng:35.845",
            false,
            result
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final prefs = await SharedPreferences.getInstance();
        _showOfflineSaveDialog(
          "strMTR_NUM:${widget.meterInfo['display_meter']},intWorkshopID:${prefs.getString('SYS_MINOR')},strWorkshopName:${prefs.getString('SYS_DESC')},strOraUserName:${prefs.getString('ORACLE_USER')},CityId:${widget.meterInfo['MTR_CITY']},CustId:${widget.meterInfo['MTR_NUM']},DisconnKind:$_selectedKind,DisconnReason:$_selectedReason,strDisconnReson:${_notesController.text.trim()},Lat:32.556,Lng:35.845",
          false,
          e.toString()
        );
      }
    }
  }

  void _showOfflineSaveDialog(String rawData, bool isConnection, String error) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('فشل الاتصال بالسيرفر'),
          content: Text('حدث خطأ: $error\n\nهل تريد حفظ الحركة محلياً للمزامنة لاحقاً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                bool saved = await DirectCurrentService.saveOfflineTransaction(rawData, isConnection);
                if (saved) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ الحركة محلياً بنجاح")));
                  if (mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل حفظ الحركة محلياً"), backgroundColor: AppTheme.accentRed));
                }
              },
              child: const Text('حفظ محلياً'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حركة فصل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: _isLoadingLists 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // كارت معلومات العداد
                  _buildInfoCard(),
                  const SizedBox(height: 25),

                  const Text('نوع الفصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildDropdown(
                    value: _selectedKind,
                    items: _kinds,
                    onChanged: (val) => setState(() => _selectedKind = val),
                  ),

                  const SizedBox(height: 20),
                  const Text('سبب الفصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildDropdown(
                    value: _selectedReason,
                    items: _reasons,
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),

              const SizedBox(height: 20),
              const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب أي تفاصيل أخرى هنا...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 40),
              if (!_isLoadingLists && (_kinds.isEmpty || _reasons.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isLoadingLists = true);
                      _loadDropdownData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("فشل جلب البيانات، اضغط لإعادة المحاولة"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
              ElevatedButton(
                onPressed: _isSaving || _kinds.isEmpty ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تأكيد وإرسال حركة الفصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person, 'المشترك:', widget.meterInfo['display_name'] ?? ""),
          _infoRow(Icons.electric_meter, 'رقم العداد:', widget.meterInfo['display_meter'] ?? ""),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String? value, required List<Map<String, String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((i) => i['id'] == value) ? value : null,
          isExpanded: true,
          alignment: Alignment.centerRight,
          hint: const Align(
            alignment: Alignment.centerRight,
            child: Text("اختر من القائمة..."),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item['id'], 
            alignment: Alignment.centerRight,
            child: Text(item['name']!, textAlign: TextAlign.right),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
