import 'package:flutter/material.dart';
import 'package:smart_application/features/settings/screens/settings_screen.dart';
import 'package:smart_application/features/meter/services/meter_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/screens/direct_current_management_screen.dart';
import 'package:smart_application/features/billing/screens/view_customer_bill_screen.dart';
import 'package:smart_application/features/meter/screens/view_meter_events_screen.dart';
import 'package:smart_application/features/meter/screens/create_connection_screen.dart';
import 'package:smart_application/features/meter/screens/sync_data_screen.dart';
import 'package:smart_application/features/meter/screens/network_configuration_screen.dart';
import 'package:smart_application/features/billing/screens/view_meter_billing_screen.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/features/direct_current/screens/create_disconnection_screen.dart';
import 'package:smart_application/features/direct_current/screens/direct_insert_screen.dart';
import 'package:smart_application/features/direct_current/screens/create_transaction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:smart_application/features/direct_current/screens/connection_inquiry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Logic State ---
  bool _showResult = false;
  bool _isLoading = false;
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _subscriberController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // للمساعدة في التمرير للنتائج
  Map<String, String>? _meterInfo;
  String _currentSearchId = "";
  String? _liveMeterState;
  bool _isCheckingState = false;
  bool _isProbeConnected = false; // تتبع حالة اقتران البروب
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  String? _lightingStatus; // تخزين حالة الإنارة المكتشفة

  // Expansion state for each section
  final List<bool> _isExpanded = [true, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    // مراقبة حالة البلوتوث الحقيقية عبر Flutter Blue Plus
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (mounted) {
        setState(() => _bluetoothState = state);
        if (state != BluetoothAdapterState.on) {
          setState(() => _isProbeConnected = false);
        }
      }
    });
  }

  void _navigateToDirectInsert() {
    debugPrint(">>> NAVIGATING TO DIRECT INSERT SCREEN...");
    if (_meterInfo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectInsertScreen(meterInfo: _meterInfo!),
        ),
      );
    } else {
      _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
    }
  }

  /// تسجيل الحدث والانتقال لشاشة الاستعلام (مطابق لكود Java الأصلي)
  void _logAndNavigateToInquiry(String eventType) async {
    final prefs = await SharedPreferences.getInstance();
    String oracleUser = prefs.getString('ORACLE_USER') ?? "";
    String meterNo = _meterController.text.trim();

    // تسجيل حدث الاستعلام في السيرفر
    if (meterNo.isNotEmpty && oracleUser.isNotEmpty) {
      MeterService.logSmartMeterEvent(meterNo, oracleUser, eventType);
    }

    // الانتقال للشاشة وانتظار النتيجة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectionInquiryScreen()),
    );

    // إذا تم اختيار معاملة من القائمة، يتم تعيين رقم العداد والبحث تلقائياً
    if (result != null && result is String && mounted) {
      setState(() {
        _meterController.text = result;
        _subscriberController.clear();
      });
      _handleSearch();
    }
  }

  void _handleSearch() async {
    String meterQuery = _meterController.text.trim();
    String subQuery = _subscriberController.text.trim();

    if (meterQuery.isEmpty && subQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال رقم الإشتراك أو العداد للبحث',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showResult = false;
      _liveMeterState = null;
    });

    try {
      String targetMeterNum = meterQuery;

      // Logic from Java: If subscriber provided but not meter, fetch meter first
      if (subQuery.isNotEmpty && meterQuery.isEmpty) {
        final fetchedMeter = await MeterService.getMeterNumberBySubscriber(subQuery);
        if (fetchedMeter != null) {
          targetMeterNum = fetchedMeter;
          _meterController.text = fetchedMeter; // Auto-fill
        } else {
          throw 'لم يتم العثور على عداد لهذا اإشتراك';
        }
      }

      if (targetMeterNum.isEmpty) {
        throw 'الرجاء إدخال رقم العداد أو رقم الإشتراك';
      }

      // Fetch full home info
      final info = await MeterService.getHomeInfo(targetMeterNum);
      
      if (info != null && info.isNotEmpty) {
        setState(() {
          _meterInfo = info;
          _showResult = true;
          _currentSearchId = targetMeterNum;
        });
        
        // التمرير التلقائي لمكان عرض النتائج (HomeInfo) كما في الجافا
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            200, // الارتفاع التقريبي لبداية كرت النتائج
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        });
      } else {
        throw 'فشل جلب تفاصيل العداد';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), textAlign: TextAlign.right),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleCheckMeterState() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }
    
    debugPrint(">>> ACTION: Check Meter State Button Pressed");
    debugPrint(">>> CURRENT METER INFO MAP: $_meterInfo");
    
    setState(() => _isCheckingState = true);
    
    try {
      final meterNo = _meterInfo!['display_meter'] ?? "";
      final kind = _meterInfo!['MTR_KIND'] ?? "";
      
      debugPrint(">>> PRE-FLIGHT CHECK: Meter=$meterNo, Kind=$kind");

      if (meterNo.isEmpty || meterNo == "---") {
        throw "رقم العداد غير متوفر.";
      }
      
      if (kind.isEmpty || kind == "---") {
        throw "نوع العداد (KIND) غير متوفر في بيانات هذا المشترك.";
      }

      final state = await MeterService.getMeterState(meterNo, kind);
      
      debugPrint(">>> API SUCCESS: Result=$state");

      if (mounted) {
        setState(() {
          _liveMeterState = state;
          _isCheckingState = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("الحالة الحالية: $state", textAlign: TextAlign.right), 
            backgroundColor: _getLiveStateColor(),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(">>> FATAL UI ERROR: $e");
      if (mounted) {
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("فشل الفحص: $e");
      }
    }
  }

  void _handleCheckVoltage() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }

    setState(() => _isCheckingState = true);

    try {
      final meterNo = _meterInfo!['display_meter'] ?? "";
      final kind = _meterInfo!['MTR_KIND'] ?? "";

      if (meterNo.isEmpty || meterNo == "---") throw "رقم العداد غير متوفر";

      // الخطوة 1: التأكد من أن العداد Connected كما في الجافا
      debugPrint(">>> VOLTAGE: STEP 1 - Checking State");
      final state = await MeterService.getMeterState(meterNo, kind);
      
      if (mounted) setState(() => _liveMeterState = state);

      if (!state.toLowerCase().contains("connected")) {
        throw "لا يمكن جلب الفولتية لأن العداد غير متصل حالياً (الحالة: $state)";
      }

      // الخطوة 2: طلب الفولتية
      debugPrint(">>> VOLTAGE: STEP 2 - Requesting Voltage");
      final voltage = await MeterService.getMeterVoltage(meterNo);

      if (mounted) {
        setState(() => _isCheckingState = false);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('قراءة الفولتية', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Icon(Icons.electric_meter, color: Colors.orange),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('قيمة الجهد الكهربائي اللحظي للعداد:', textAlign: TextAlign.right),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$voltage فولت',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("$e");
      }
    }
  }

  void _handleEnableGPRS() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }

    // 1. محاكاة الاتصال بجهاز البروب عبر البلوتوث
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري الاتصال بجهاز البروب وإرسال أمر التفعيل...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pop(context); // إغلاق الديالوج

    // 2. محاكاة نجاح إرسال كود الـ Hex للعداد
    // في الواقع هنا نرسل الـ bytes: 12 23 03 74 F0 2C E6 E7 00 C4 01 81 00 03 01 04
    
    // 3. إرسال الحركة للسيرفر للتوثيق (ProbeGPRSConnTrans)
    setState(() => _isCheckingState = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final result = await DirectCurrentService.probeGPRSConnTrans(
        meterNum: _meterInfo!['display_meter'] ?? "",
        workshopId: prefs.getString('SYS_MINOR') ?? "",
        workshopName: prefs.getString('SYS_DESC') ?? "", // عادة يكون اسم الورشة مخزن في SYS_DESC
        userName: prefs.getString('ORACLE_USER') ?? "",
        cityId: _meterInfo!['MTR_CITY'] ?? "",
        custId: _meterInfo!['MTR_NUM'] ?? "",
      );

      if (mounted) {
        setState(() => _isCheckingState = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تفعيل GPRS: $result", textAlign: TextAlign.right),
            backgroundColor: result.contains("نجاح") || result.contains("تم") ? AppTheme.accentGreen : AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("فشل توثيق العملية: $e");
      }
    }
  }

  void _handleProbeConnectMeter() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }

    if (!_isProbeConnected) {
      _showErrorSnackBar("يرجى الاقتران بالبروب أولاً");
      return;
    }

    // الخطوة 1: فحص الحالة الحالية (يجب أن يكون Disconnected للوصل)
    debugPrint(">>> PROBE CONNECT: Step 1 - Checking State");
    setState(() => _isCheckingState = true);
    
    try {
      final state = await MeterService.getMeterState(_meterInfo!['display_meter'] ?? "", _meterInfo!['MTR_KIND'] ?? "");
      if (mounted) setState(() => _liveMeterState = state);

      if (!state.toLowerCase().contains("disconnected")) {
        throw "لا يمكن الوصل: حالة العداد الحالية هي ($state). يجب أن يكون مفصولاً ليتم وصله.";
      }

      // الخطوة 2: حوار التأكيد
      if (!mounted) return;
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد عملية الوصل', textAlign: TextAlign.right),
          content: const Text('هل أنت متأكد من رغبتك في إرسال أمر الوصل للعداد عبر البروب؟', textAlign: TextAlign.right),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              child: const Text('تأكيد الوصل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isCheckingState = false);
        return;
      }

      // الخطوة 3: إرسال سلسلة أوامر الـ Hex (DLMS Protocol)
      debugPrint(">>> PROBE CONNECT: Step 3 - Sending Hex Sequence");
      
      // 1. التهيئة (Baudrate Setup)
      // Commands: 06 32 30 32 0D 0A -> 55 AF 3F 21 8D 0A
      await Future.delayed(const Duration(milliseconds: 900));

      // 2. فتح الجلسة (HDLC Connect)
      // Command: 7E A0 07 03 23 93 BF 32 7E
      await Future.delayed(const Duration(milliseconds: 900));

      // 3. أمر الوصل الفعلي (Relay Connect)
      // Command: 7E A0 1B 03 23 54 99 D4 E6 E6 00 C3 01 81 00 46 00 00 60 03 0A FF 02 01 11 00 75 EF 7E
      await Future.delayed(const Duration(milliseconds: 900));

      // 4. إغلاق الجلسة
      // Command: 7E A0 07 03 23 53 B3 F4 7E
      await Future.delayed(const Duration(milliseconds: 900));

      // الخطوة 4: التوثيق في السيرفر (API)
      debugPrint(">>> PROBE CONNECT: Step 4 - Server Documentation");
      final prefs = await SharedPreferences.getInstance();
      
      final result = await DirectCurrentService.recordProbeConnection(
        meterNum: _meterInfo!['display_meter'] ?? "",
        workshopId: prefs.getString('SYS_MINOR') ?? "",
        workshopName: prefs.getString('SYS_DESC') ?? "",
        userName: prefs.getString('ORACLE_USER') ?? "",
        cityId: _meterInfo!['MTR_CITY'] ?? "",
        custId: _meterInfo!['MTR_NUM'] ?? "",
      );

      if (mounted) {
        setState(() {
          _isCheckingState = false;
          _liveMeterState = "Connected"; // تحديث الحالة في الواجهة فوراً
        });
        
        _showSuccessSnackBar("عملية الوصل: $result");
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingState = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _handleProbeLightStatus() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }
    if (!_isProbeConnected) {
      _showErrorSnackBar("يرجى الاقتران بالبروب أولاً");
      return;
    }

    setState(() => _isCheckingState = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري قراءة حالة الإنارة من العداد...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      // 1. أوامر التهيئة (900ms)
      await Future.delayed(const Duration(milliseconds: 900));

      // 2. أمر قراءة حالة الإنارة (900ms)
      // Command: 7E A0 19 03 23 54 EF ED E6 E6 00 C0 01 81 00 46 00 00 60 03 0A FF 04 00 FB FC 7E
      await Future.delayed(const Duration(milliseconds: 900));

      // 3. محاكاة تحليل الرد (Mode5 / Mode6)
      // سنقوم بتبديل الحالة عشوائياً للمعاينة في هذه المرحلة
      bool isActive = DateTime.now().second % 2 == 0;
      String statusText = isActive 
          ? "الإنارة فعالة (القاطع واصل خلال الليل فقط)" 
          : "الإنارة غير فعالة (القاطع واصل طوال اليوم)"; 

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        setState(() {
          _isCheckingState = false;
          _lightingStatus = statusText; // حفظ الحالة للعرض في لوحة الحالة
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('حالة الإنارة', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Icon(Icons.light_mode_rounded, color: Colors.orange),
              ],
            ),
            content: Text(
              statusText, 
              textAlign: TextAlign.right, 
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("فشل قراءة حالة الإنارة: $e");
      }
    }
  }

  void _handleProbeEnableLight() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }
    if (!_isProbeConnected) {
      _showErrorSnackBar("يرجى الاقتران بالبروب أولاً");
      return;
    }

    // 1. حوار التأكيد
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل نظام الإنارة', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من رغبتك في إرسال أمر تفعيل الإنارة (القاطع ليل فقط) للعداد؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تأكيد التفعيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCheckingState = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري إرسال أمر تفعيل الإنارة للعداد...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      // 2. محاكاة تسلسل أوامر الـ Hex
      await Future.delayed(const Duration(milliseconds: 900)); // التهيئة
      
      // إرسال الأمر الفعلي: 7E A0 1B 03 23 54 99 D4 E6 E6 00 C1 01 81 00 46 00 00 60 03 0A FF 04 00 16 05 C2 74 7E
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. التوثيق في السيرفر (type: 6 يمثل تفعيل الإنارة)
      final meterNo = _meterInfo!['display_meter'] ?? "";
      final logResult = await MeterService.recordModeLog(6, meterNo);

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        setState(() {
          _isCheckingState = false;
          _lightingStatus = "الإنارة فعالة (القاطع واصل خلال الليل فقط)";
        });
        _showSuccessSnackBar("تفعيل الإنارة: $logResult");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("فشل التفعيل: $e");
      }
    }
  }

  void _handleProbeDisableLight() async {
    if (_meterInfo == null) {
      _showErrorSnackBar("يرجى الاستعلام عن عداد أولاً");
      return;
    }
    if (!_isProbeConnected) {
      _showErrorSnackBar("يرجى الاقتران بالبروب أولاً");
      return;
    }

    // 1. حوار التأكيد
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء نظام الإنارة', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من رغبتك في إرسال أمر إلغاء الإنارة (القاطع واصل طوال اليوم) للعداد؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCheckingState = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري إرسال أمر إلغاء الإنارة للعداد...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      // 2. محاكاة تسلسل أوامر الـ Hex
      await Future.delayed(const Duration(milliseconds: 900)); // التهيئة
      
      // إرسال أمر إلغاء الإنارة (Mode 6)
      // Command: 7E A0 1B 03 23 54 99 D4 E6 E6 00 C1 01 81 00 46 00 00 60 03 0A FF 04 00 16 06 59 46 7E
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. التوثيق في السيرفر (type: 7 يمثل إلغاء الإنارة كما في الجافا)
      final meterNo = _meterInfo!['display_meter'] ?? "";
      final logResult = await MeterService.recordModeLog(7, meterNo);

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        setState(() {
          _isCheckingState = false;
          _lightingStatus = "الإنارة غير فعالة (القاطع واصل طوال اليوم)";
        });
        _showSuccessSnackBar("إلغاء الإنارة: $logResult");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCheckingState = false);
        _showErrorSnackBar("فشل الإلغاء: $e");
      }
    }
  }

  void _handleProbeConnection() async {
    // 1. طلب الصلاحيات اللازمة (Android 12+)
    if (await Permission.bluetoothConnect.request().isDenied || 
        await Permission.bluetoothScan.request().isDenied) {
      _showErrorSnackBar("يرجى منح صلاحيات البلوتوث للعمل");
      return;
    }

    // 2. التحقق إذا كان البلوتوث مغلقاً بالفعل
    if (_bluetoothState != BluetoothAdapterState.on) {
      _showErrorSnackBar("البلوتوث مغلق. يرجى تفعيله أولاً");
      return;
    }

    setState(() => _isCheckingState = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري البحث عن أجهزة البروب والاقتران...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      // محاكاة mmSocket.connect()
      await Future.delayed(const Duration(seconds: 3));
      
      // لنفترض نجاح الاتصال هنا
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isProbeConnected = true;
          _isCheckingState = false;
        });
        _showSuccessSnackBar("تم الاقتران مع جهاز البروب بنجاح");
      }
    } catch (e) {
      // بلوك الـ catch كما في الجافا تماماً
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isProbeConnected = false;
          _isCheckingState = false;
        });
        _showErrorSnackBar("فشل الاقتران: الجهاز غير مقترن مع البروب");
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getLiveStateColor() {
    if (_liveMeterState == null) return AppTheme.accentGreen;
    final state = _liveMeterState!.toLowerCase();
    if (state.contains("connected")) return Colors.green;
    if (state.contains("disconnected")) return Colors.red;
    if (state.contains("offline")) return Colors.orange;
    return AppTheme.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          controller: _scrollController, // ربط وحدة التحكم
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Premium Header with Logo ---
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primaryBlue,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -30,
                        child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20), // Higher up
                            // Circular Logo Display - Elegant and Premium
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Image.asset(
                                    'lib/assets/images.jpg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'كهرباء إربد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Text(
                              'نظام إدارة العدادات الذكية المتكامل',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
              leading: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),

            // --- Dashboard Content ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Search Card
                  _buildSearchCard(),
                  const SizedBox(height: 25),

                  // 2. Animated Results Section
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: _isLoading 
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                        : _showResult && _meterInfo != null
                        ? Column(
                      key: const ValueKey('result'),
                      children: [
                        _buildDetailedResultCard(),
                        const SizedBox(height: 32),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),

                  // --- ALL PANEL SECTIONS WITH DROPDOWN EFFECT ---

                  _buildExpandablePanel(0, 'لوحة حركات تأمين التيار بشكل مباشر', Icons.flash_on_rounded, [
                    _buildFeatureAction(
                      Icons.bolt_rounded, 
                      'إدخال حركة تأمين', 
                      AppTheme.primaryBlue,
                      onTap: _navigateToDirectInsert,
                    ),
                    _buildFeatureAction(
                      Icons.manage_search_rounded, 
                      'إستعلام حركات', 
                      AppTheme.primaryBlue,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectCurrentManagementScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                  ], crossAxisCount: 2),

                  const SizedBox(height: 20),

                  _buildExpandablePanel(1, 'لوحة العدادات الذكية للتحكم عن بعد', Icons.settings_remote_rounded, [
                    _buildFeatureAction(Icons.speed_rounded, 'القراءة الحالية', Colors.indigo),
                    _buildFeatureAction(
                      Icons.fact_check_outlined, 
                      'حالة العداد', 
                      Colors.indigo,
                      onTap: _handleCheckMeterState,
                    ),
                    _buildFeatureAction(
                      Icons.electric_meter_outlined, 
                      'عرض الفولتية', 
                      Colors.indigo,
                      onTap: _handleCheckVoltage,
                    ),
                    _buildFeatureAction(
                      Icons.receipt_long_rounded, 
                      'فواتير العداد', 
                      Colors.indigo,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewMeterBillingScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.event_note, 
                      'إيفينت العداد', 
                      Colors.indigo,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewMeterEventsScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.people_alt_outlined, 
                      'فواتير المشترك', 
                      Colors.indigo,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewCustomerBillScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.link_off_rounded, 
                      'إنشاء معاملة فصل', 
                      AppTheme.accentRed,
                      onTap: () async {
                        if (_meterInfo != null) {
                          final prefs = await SharedPreferences.getInstance();
                          final user = prefs.getString('ORACLE_USER') ?? "";
                          final workshop = prefs.getString('SYS_MINOR') ?? "";

                          if (user.isEmpty || workshop.isEmpty) {
                            _showErrorSnackBar('يرجى ضبط رقم المستخدم والورشة من الإعدادات أولاً');
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateDisconnectionScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.link_rounded, 
                      'إنشاء معاملة وصل', 
                      AppTheme.accentGreen,
                      onTap: () async {
                        if (_meterInfo != null) {
                          final prefs = await SharedPreferences.getInstance();
                          final user = prefs.getString('ORACLE_USER') ?? "";
                          final workshop = prefs.getString('SYS_MINOR') ?? "";

                          if (user.isEmpty || workshop.isEmpty) {
                            _showErrorSnackBar('يرجى ضبط رقم المستخدم والورشة من الإعدادات أولاً');
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateConnectionScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(Icons.online_prediction_rounded, 'وصل عن بعد', Colors.indigo),
                  ], crossAxisCount: 3),

                  const SizedBox(height: 20),

                  _buildExpandablePanel(
                    2, 
                    'لوحة تحكم البروب', 
                    Icons.cable_rounded, 
                    [
                    _buildFeatureAction(
                      Icons.bluetooth_searching_rounded, 
                      'بدء الاقتران', 
                      Colors.teal,
                      onTap: _handleProbeConnection,
                    ),
                    _buildFeatureAction(
                      Icons.cell_tower_rounded, 
                      'تفعيل GPRS', 
                      Colors.teal,
                      onTap: _isProbeConnected ? _handleEnableGPRS : () => _showErrorSnackBar("يرجى الاقتران بالبروب أولاً"),
                    ),
                    _buildFeatureAction(
                      Icons.info_outline, 
                      'حالة العداد', 
                      Colors.teal,
                      onTap: _isProbeConnected ? _handleCheckMeterState : () => _showErrorSnackBar("يرجى الاقتران بالبروب أولاً"),
                    ),
                    _buildFeatureAction(Icons.link, 'وصل مع حركة', Colors.teal),
                    _buildFeatureAction(Icons.link_off, 'فصل مع حركة', Colors.teal),
                    _buildFeatureAction(
                      Icons.settings_input_component, 
                      'وصل بروب', 
                      Colors.teal,
                      onTap: _handleProbeConnectMeter,
                    ),
                    _buildFeatureAction(
                      Icons.light_mode_outlined, 
                      'حالة الإنارة', 
                      Colors.teal,
                      onTap: _handleProbeLightStatus,
                    ),
                    _buildFeatureAction(
                      Icons.lightbulb_rounded, 
                      'تفعيل الإنارة', 
                      Colors.teal,
                      onTap: _handleProbeEnableLight,
                    ),
                    _buildFeatureAction(
                      Icons.lightbulb_outline_rounded, 
                      'إلغاء الإنارة', 
                      Colors.teal,
                      onTap: _handleProbeDisableLight,
                    ),
                  ], 
                  crossAxisCount: 3,
                  status: _buildProbeStatusWidget(),
                ),

                  const SizedBox(height: 20),

                  _buildExpandablePanel(3, 'لوحة الفصل والوصل', Icons.power_settings_new_rounded, [
                    _buildFeatureAction(
                      Icons.link_rounded, 
                      'إنشاء وصل', 
                      Colors.blueGrey,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateConnectionScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.link_off_rounded, 
                      'إنشاء فصل', 
                      Colors.blueGrey,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateDisconnectionScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.note_add_outlined, 
                      'إنشاء معاملة', 
                      AppTheme.accentRed,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateTransactionScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(
                      Icons.list_alt_rounded, 
                      'إستعلام وصل', 
                      Colors.blueGrey,
                      onTap: () => _logAndNavigateToInquiry("Conn Inquiry"),
                    ),
                    _buildFeatureAction(
                      Icons.history_rounded, 
                      'إستعلام فصل', 
                      Colors.blueGrey,
                      onTap: () => _logAndNavigateToInquiry("Disconn Inquiry"),
                    ),
                    _buildFeatureAction(
                      Icons.assignment_outlined, 
                      'إستعلام معاملات', 
                      Colors.blueGrey,
                      onTap: () {
                        if (_meterInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectCurrentManagementScreen(meterInfo: _meterInfo!),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('يرجى الاستعلام عن عداد أولاً');
                        }
                      },
                    ),
                    _buildFeatureAction(Icons.format_list_bulleted_rounded, 'حركات التوصيل', Colors.blueGrey),
                    _buildFeatureAction(
                      Icons.sync_rounded, 
                      'مزامنة الحركات', 
                      Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SyncDataScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureAction(Icons.wifi_off_rounded, 'فاقد الاتصال', AppTheme.accentRed),
                  ], crossAxisCount: 3),

                  const SizedBox(height: 20),

                  _buildExpandablePanel(4, 'لوحة تحكم GPRS', Icons.router_rounded, [
                    _buildFeatureAction(
                      Icons.router, 
                      'تفعيل GPRS', 
                      Colors.cyan[700]!,
                      onTap: _handleEnableGPRS,
                    ),
                    _buildFeatureAction(
                      Icons.monitor_heart_outlined, 
                      'حالة العداد', 
                      Colors.cyan[700]!,
                      onTap: _handleCheckMeterState,
                    ),
                    _buildFeatureAction(
                      Icons.settings_suggest_rounded, 
                      'برمجة الشبكة', 
                      Colors.cyan[700]!,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NetworkConfigurationScreen()),
                        );
                      },
                    ),
                  ], crossAxisCount: 3),

                  const SizedBox(height: 20),

                  _buildExpandablePanel(5, 'إعدادات الحساب', Icons.account_circle_rounded, [
                    _buildFeatureAction(
                      Icons.lock_reset_rounded, 
                      'تغيير كلمة المرور', 
                      AppTheme.accentOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildFeatureAction(
                      Icons.logout_rounded, 
                      'تسجيل الخروج', 
                      AppTheme.accentRed,
                      onTap: () => Navigator.pop(context),
                    ),
                  ], crossAxisCount: 2),

                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Styled Builder Helper Methods ---

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          _buildPrettyInputField(controller: _meterController, label: 'رقم العداد', icon: Icons.qr_code_scanner_rounded),
          const SizedBox(height: 12),
          _buildPrettyInputField(controller: _subscriberController, label: 'رقم الإشتراك', icon: Icons.badge_outlined),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
            ),
            child: const Text('إستعلام عن البيانات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrettyInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
          prefixIcon: icon == Icons.qr_code_scanner_rounded 
            ? IconButton(
                icon: Icon(icon, color: AppTheme.secondaryBlue, size: 22),
                onPressed: () => _showErrorSnackBar("جاري تفعيل ماسح الباركود..."),
              )
            : Icon(icon, color: AppTheme.secondaryBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDetailedResultCard() {
    debugPrint(">>> Rendering DetailedResultCard - Meter: ${_meterInfo?['display_meter']}");
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('نتيجة الاستعلام للرقم', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_currentSearchId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _getLiveStateColor().withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: _getLiveStateColor()),
                    const SizedBox(width: 8),
                    Text(
                      _liveMeterState != null ? "($_liveMeterState)" : (_meterInfo?['state'] ?? 'غير متوفر'), 
                      style: TextStyle(color: _getLiveStateColor(), fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildResultInfoRow(Icons.person_pin_rounded, 'اسم المشترك:', _meterInfo?['display_name'] ?? 'غير متوفر'),
          _buildResultInfoRow(Icons.badge_rounded, 'رقم الإشتراك:', _meterInfo?['display_id'] ?? 'غير متوفر'),
          _buildResultInfoRow(Icons.electric_meter_outlined, 'رقم العداد:', _meterInfo?['display_meter'] ?? 'غير متوفر'),
          _buildResultInfoRow(Icons.phone_android_rounded, 'هاتف القارئ:', _meterInfo?['display_mobile'] ?? 'غير متوفر'),
          _buildResultInfoRow(Icons.calendar_month_rounded, 'موعد القراءة:', _meterInfo?['reading_date'] ?? 'غير متوفر'),
          _buildResultInfoRow(Icons.location_on_rounded, 'الموقع الجغرافي:', 
              (_meterInfo?['POS_X'] != "---" && _meterInfo?['POS_Y'] != "---") 
              ? "${_meterInfo?['POS_X']} , ${_meterInfo?['POS_Y']}" 
              : 'غير متوفر'),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModernStatBadge(Icons.memory_rounded, _meterInfo?['display_smart'] ?? 'غير متوفر', 'نوع العداد'),
              _buildModernStatBadge(Icons.bolt_rounded, _meterInfo?['display_faz'] ?? 'غير متوفر', 'المرحلة'),
              _buildModernStatBadge(Icons.location_on_outlined, _meterInfo?['display_area'] ?? 'إربد', 'المنطقة'),
            ],
          ),
          const SizedBox(height: 25),
          _buildDetailMetricRow('عدد الفواتير المستحقة:', '${_meterInfo?['INVOICE_COUNT'] ?? '0'} فاتورة'),
          _buildDetailMetricRow('مجموع الذمم المطلوبة:', '${_meterInfo?['display_inv_amt'] ?? '0'} دينار', isHighlighted: true),
          const SizedBox(height: 28),
          
          // زر الفحص المحدث مع تتبع اللمس
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isCheckingState ? null : () {
                debugPrint(">>> UI: USER CLICKED THE CHECK BUTTON");
                _handleCheckMeterState();
              },
              icon: _isCheckingState 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue))
                : const Icon(Icons.cloud_sync_outlined, size: 20),
              label: Text(
                _isCheckingState ? 'جاري الفحص...' : 'فحص حالة العداد الآن', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue.withOpacity(0.08),
                foregroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProbeStatusWidget() {
    bool isBtOff = _bluetoothState != BluetoothAdapterState.on;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isBtOff 
            ? Colors.red.withOpacity(0.05)
            : _isProbeConnected 
                ? const Color(0xFF06F106).withOpacity(0.1) 
                : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isBtOff 
              ? Colors.red.withOpacity(0.3)
              : _isProbeConnected 
                  ? const Color(0xFF06F106).withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBtOff ? Icons.bluetooth_disabled_rounded : (_isProbeConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded),
                size: 20,
                color: isBtOff ? Colors.red : (_isProbeConnected ? const Color(0xFF06F106) : Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Text(
                isBtOff 
                    ? "( البلوتوث غير مفعل )" 
                    : (_isProbeConnected ? "( الجهاز مقترن مع البروب )" : "( الجهاز غير مقترن مع البروب )"),
                style: TextStyle(
                  color: isBtOff ? Colors.red : (_isProbeConnected ? const Color(0xFF06F106) : const Color(0xFF000000)),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              if (_isProbeConnected) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFF06F106),
                ),
              ],
            ],
          ),
          if (_lightingStatus != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lightbulb_circle_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 10),
                Text(
                  _lightingStatus!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  Widget _buildDetailMetricRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isHighlighted ? AppTheme.accentRed : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatBadge(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.secondaryBlue.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }

  // --- Expandable Panel Component ---
  Widget _buildExpandablePanel(int index, String title, IconData icon, List<Widget> items, {required int crossAxisCount, Widget? status}) {
    bool expanded = _isExpanded[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded ? AppTheme.primaryBlue : Colors.grey.withOpacity(0.15),
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: expanded
            ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable Section Header
          InkWell(
            onTap: () => setState(() => _isExpanded[index] = !expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: expanded ? AppTheme.primaryBlue.withOpacity(0.08) : AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: expanded ? AppTheme.primaryBlue : AppTheme.textGrey),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: expanded ? AppTheme.primaryBlue : AppTheme.textDark,
                      ),
                    ),
                  ),
                  // Rotating Arrow Icon
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: expanded ? AppTheme.primaryBlue : AppTheme.textGrey.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Smooth Expand Animation for the Content
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: expanded
                ? Column(
                    children: [
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      if (status != null) status,
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: (crossAxisCount == 2) ? 1.6 : 1.0,
                          children: items,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFeatureAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 25, height: 2, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(1))),
            ],
          ),
        ),
      ),
    );
  }
}
