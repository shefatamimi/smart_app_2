import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_application/features/meter/screens/home_screen.dart';
import 'package:smart_application/features/auth/services/auth_service.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to capture user input
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المستخدم وكلمة المرور', textAlign: TextAlign.right),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calling the API service for authentication (saves data internally)
      final success = await AuthService.login(username, password);

      if (!mounted) return;

      if (success) {
        // Navigate to HomeScreen on successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تسجيل الدخول. يرجى التحقق من البيانات', textAlign: TextAlign.right),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الاتصال: $e', textAlign: TextAlign.right),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: Stack(
        children: [
          // Elegant decorative background (top-right accent)
          Positioned(
            top: -150,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.04),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10), // Extremely close to top as requested
                      // --- Premium Logo ---
                      Container(
                        height: 180, 
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withAlpha(38),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: AppTheme.surfaceWhite, width: 6),
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
                      const SizedBox(height: 15),
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'نظام إدارة العدادات الذكية المتكامل',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 35),
                      // --- Premium Login Form ---
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextField(
                                controller: _usernameController,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  labelStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
                                  filled: true,
                                  fillColor: AppTheme.backgroundGrey,
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextField(
                                controller: _passwordController,
                                textAlign: TextAlign.right,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'كلمة السر',
                                  labelStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
                                  filled: true,
                                  fillColor: AppTheme.backgroundGrey,
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 35),
                            // Gradient Login Button
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(
                                      width: 25, 
                                      height: 25, 
                                      child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2)
                                    )
                                  : const Text(
                                      'دخول للنظام',
                                      style: TextStyle(
                                        color: AppTheme.surfaceWhite,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            )
          ],
        ),
      );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
