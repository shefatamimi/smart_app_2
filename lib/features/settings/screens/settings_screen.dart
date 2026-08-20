import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/auth/services/auth_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  void _handleChangePassword() async {
    final oldPassInput = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPassInput.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('الرجاء تعبئة جميع الحقول', AppTheme.accentOrange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPass = prefs.getString('password') ?? '';
      final userId = prefs.getString('ID') ?? '';

      // 1. التحقق من كلمة السر القديمة
      if (oldPassInput != storedPass) {
        _showSnackBar('كلمة السر القديمة خاطئة', AppTheme.accentRed);
        setState(() => _isLoading = false);
        return;
      }

      // 2. التحقق من تطابق الجديدتين
      if (newPass != confirmPass) {
        _showSnackBar('كلمة السر الجديدة غير متطابقة', AppTheme.accentRed);
        setState(() => _isLoading = false);
        return;
      }

      // 3. التحقق من الطول
      if (newPass.length <= 3) {
        _showSnackBar('يرجى إستخدام كلمة سر أطول من 3 حروف', AppTheme.accentRed);
        setState(() => _isLoading = false);
        return;
      }

      // تشغيل عملية التحديث
      final result = await AuthService.updateUserPass(newPass, userId);

      // في أنظمة IDECO القديمة، النجاح يرجع كلمة "true"
      if (result.toLowerCase() == "true") {
        _showSnackBar('تم تغيير كلمة السر بنجاح. يرجى إعادة تسجيل الدخول', AppTheme.accentGreen);
        
        if (mounted) {
          Future.delayed(const Duration(seconds: 2), () async {
            // مسح الجلسة والتوجه للوق ان كما في الجافا
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          });
        }
      } else {
        _showSnackBar(result.contains("error") ? "فشل التحديث من السيرفر" : result, AppTheme.accentRed);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ: $e', AppTheme.accentRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Card Container matching the screenshot style
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'تغيير كلمة سر المستخدم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 25),
                    _buildInputField(
                      controller: _oldPassController,
                      label: 'كلمة السر القديمة',
                      icon: Icons.lock_open_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _newPassController,
                      label: 'كلمة السر الجديدة',
                      icon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _confirmPassController,
                      label: 'تأكيد لكلمة السر الجديدة',
                      icon: Icons.verified_user_outlined,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تغيير كلمة سر المستخدم',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.secondaryBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }
}
