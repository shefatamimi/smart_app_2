import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // جلب البيانات الحقيقية للموظف من SharedPreferences كما في الجافا
      final String workshopId = prefs.getString('SYS_MINOR') ?? "0";
      final String workshopName = prefs.getString('SYS_DESC') ?? "غير معروف";
      final String oracleUser = prefs.getString('ORACLE_USER') ?? "UNKNOWN";
      
      final result = await DirectCurrentService.connTrans(
        meterNum: widget.meterInfo['display_meter'] ?? "",
        workshopId: workshopId,
        workshopName: workshopName,
        userName: oracleUser,
        cityId: widget.meterInfo['MTR_CITY'] ?? "",
        custId: widget.meterInfo['MTR_NUM'] ?? "",
        lat: 0.0,
        lng: 0.0,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
        if (result.contains("نجاح") || result.contains("تم")) {
          _showResult(result);
          Navigator.pop(context);
        } else {
          _showOfflineSaveDialog(
            "strMTR_NUM:${widget.meterInfo['display_meter']},intWorkshopID:$workshopId,strWorkshopName:$workshopName,strOraUserName:$oracleUser,CityId:${widget.meterInfo['MTR_CITY']},CustId:${widget.meterInfo['MTR_NUM']},Lat:0.0,Lng:0.0",
            true,
            result
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final prefs = await SharedPreferences.getInstance();
        _showOfflineSaveDialog(
          "strMTR_NUM:${widget.meterInfo['display_meter']},intWorkshopID:${prefs.getString('SYS_MINOR')},strWorkshopName:${prefs.getString('SYS_DESC')},strOraUserName:${prefs.getString('ORACLE_USER')},CityId:${widget.meterInfo['MTR_CITY']},CustId:${widget.meterInfo['MTR_NUM']},Lat:0.0,Lng:0.0",
          true,
          e.toString()
        );
      }
    }
  }

  void _showOfflineSaveDialog(String rawData, bool isConnection, String error) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
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
                  _showResult("تم حفظ الحركة محلياً بنجاح");
                  if (mounted) Navigator.pop(context);
                } else {
                  _showResult("فشل حفظ الحركة محلياً");
                }
              },
              child: const Text('حفظ محلياً'),
            ),
          ],
        ),
      ),
    );
  }


  void _showResult(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: msg.contains("نجاح") ? AppTheme.accentGreen : AppTheme.accentRed),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
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
              // Circular Logo
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('lib/assets/images.jpg', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'إنشاء حركة وصل',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.qr_code_2_rounded, 'رقم العداد', widget.meterInfo['display_meter'] ?? '---'),
                        _buildInfoRow(Icons.person_rounded, 'اسم المشترك', widget.meterInfo['display_name'] ?? '---'),
                        _buildInfoRow(Icons.phone_rounded, 'هاتف المشترك', widget.meterInfo['CUSM_TELEPHONE'] ?? '---'),
                        _buildInfoRow(Icons.location_on_rounded, 'العنوان', widget.meterInfo['display_area'] ?? '---'),
                        _buildInfoRow(Icons.link_off_rounded, 'نوع الفصل', widget.meterInfo['SEP_TYPE_DESC'] ?? '---'),
                        _buildInfoRow(Icons.calendar_month_rounded, 'تاريخ الفصل', widget.meterInfo['SEP_DATE'] ?? '---'),
                        _buildInfoRow(Icons.info_outline_rounded, 'الحالة الحالية', widget.meterInfo['STATUS_DESC'] ?? '---'),
                      ],
                    ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.04),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label, 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13, 
                      color: AppTheme.textGrey
                    )
                  )
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                value, 
                style: const TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w900, 
                  color: AppTheme.primaryBlue
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 15, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleConnection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isProcessing 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'تفعيل وإرسال حركة الوصل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
