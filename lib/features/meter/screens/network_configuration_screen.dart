import 'package:flutter/material.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class NetworkConfigurationScreen extends StatefulWidget {
  const NetworkConfigurationScreen({super.key});

  @override
  State<NetworkConfigurationScreen> createState() => _NetworkConfigurationScreenState();
}

class _NetworkConfigurationScreenState extends State<NetworkConfigurationScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _apnController = TextEditingController();
  
  String? _selectedConfig = 'إختر إعداد مسبق';
  bool _isReading = false;
  bool _isSaving = false;

  // قائمة الإعدادات المسبقة كما في الجافا
  final List<String> _presets = [
    'إختر إعداد مسبق',
    'Holley - Production',
    'Hexing - Production',
    'Holley - Testing',
    'Hexing - Testing',
  ];

  @override
  void initState() {
    super.initState();
    // محاكاة جلب الإعدادات الحالية عند الفتح (pos = 1 في الجافا)
    _readCurrentConfiguration();
  }

  void _readCurrentConfiguration() async {
    setState(() => _isReading = true);
    
    // محاكاة الاتصال بالبروب والقراءة
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _ipController.text = "10.10.20.50";
        _portController.text = "4040";
        _apnController.text = "ideco.m2m";
        _isReading = false;
      });
      _showSnackBar('تمت قراءة إعدادات العداد الحالية', AppTheme.accentGreen);
    }
  }

  void _handleSaveConfiguration() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty || _apnController.text.isEmpty) {
      _showSnackBar('الرجاء التأكد من تعبئة جميع الحقول', AppTheme.accentOrange);
      return;
    }

    setState(() => _isSaving = true);

    // محاكاة عملية البرمجة (SetDlmsMeterNetwork)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isSaving = false);
      _showSnackBar('تمت برمجة شبكة العداد بنجاح', AppTheme.accentGreen);
      // Navigator.pop(context);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('برمجة شبكة عداد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isReading ? null : _readCurrentConfiguration,
            tooltip: 'تحديث البيانات من العداد',
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isReading)
                const LinearProgressIndicator(backgroundColor: Colors.white, color: AppTheme.secondaryBlue),
              
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 12))
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.router_rounded, size: 50, color: AppTheme.secondaryBlue),
                    const SizedBox(height: 15),
                    const Text(
                      'إعدادات الشبكة (GPRS)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 30),
                    
                    // Spinner / Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedConfig,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.secondaryBlue),
                          items: _presets.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedConfig = newValue;
                              // محاكاة تعبئة الحقول بناءً على الاختيار
                              if (newValue != 'إختر إعداد مسبق') {
                                if (newValue!.contains('Production')) {
                                  _ipController.text = "10.10.20.50";
                                  _portController.text = "4040";
                                } else {
                                  _ipController.text = "192.168.10.15";
                                  _portController.text = "8080";
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _ipController,
                      label: 'IP Address',
                      icon: Icons.lan_outlined,
                      hint: '0.0.0.0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _portController,
                      label: 'Port',
                      icon: Icons.numbers_rounded,
                      hint: '4040',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _apnController,
                      label: 'APN',
                      icon: Icons.settings_input_antenna_rounded,
                      hint: 'ideco.m2m',
                    ),
                    
                    const SizedBox(height: 35),
                    
                    ElevatedButton(
                      onPressed: (_isSaving || _isReading) ? null : _handleSaveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: AppTheme.secondaryBlue.withValues(alpha: 0.4),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'برمجة شبكة العداد',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // التنبيهات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تأكد من اقتران جهاز الـ Probe بالبلوتوث وتوصيله بالعداد قبل البدء.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.left, // العناوين بالإنجليزية غالباً
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: AppTheme.secondaryBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }
}
