import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry/sentry.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final success = await ref.read(authProvider.notifier).loginOrganization(email, password);
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).errorMessage ?? 'Invalid organization credentials',
            style: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleQuickDemoLogin({String userName = 'Amrit Maurya'}) async {
    await ref.read(authProvider.notifier).setDemoSession(userName: userName);
    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  void _fillDemoCredentials(String label, String email) {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = 'Test@123456';
    });
    final name = label.contains('(') ? label.split('(').first.trim() : label;
    _handleQuickDemoLogin(userName: name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = true;
    const brandGold = AppColors.primary;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 384.w,
              height: 384.h,
              decoration: BoxDecoration(
                color: brandGold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandGold.withValues(alpha: 0.08),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 460.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: brandGold,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Icon(Icons.restaurant, color: Color(0xFF1F1F1F), size: 28),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Restro ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: const Color(0xFFF5F5F5),
                            ),
                          ),
                          Text(
                            'POS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: brandGold,
                            ),
                          ),
                        ],
                      ),
                      Gap(16.h),
                      Text(
                        'Restaurant Sign In',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Enter your credentials to manage orders, tables, and staff',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          color: const Color(0xFFABABAB),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      Gap(32.h),

                      // Credentials Form Card
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF232627) : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              Text(
                                'Organization Email',
                                style: TextStyle(fontFamily: 'PlusJakartaSans',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Gap(8.h),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(fontFamily: 'PlusJakartaSans',fontSize: 14.sp),
                                decoration: InputDecoration(
                                  hintText: 'name@organization.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter email address';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              Gap(20.h),

                              // Password Field
                              Text(
                                'Password',
                                style: TextStyle(fontFamily: 'PlusJakartaSans',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Gap(8.h),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(fontFamily: 'PlusJakartaSans',fontSize: 14.sp),
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              Gap(24.h),

                              // Submit Button
                              authState.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(brandGold),
                                      ),
                                    )
                                  : SizedBox(
                                                                           child: FilledButton(
                                        onPressed: _handleLogin,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: brandGold,
                                          foregroundColor: const Color(0xFF1F1F1F),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        ),
                                        child: Text(
                                          'Sign In to Restro POS',
                                          style: TextStyle(fontFamily: 'Inter',
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                              Gap(12.h),
                              OutlinedButton.icon(
                                onPressed: () => _handleQuickDemoLogin(userName: 'Amrit Maurya'),
                                icon: const Icon(Icons.flash_on, color: brandGold, size: 18),
                                label: Text(
                                  '⚡ One-Click Demo Mode',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: brandGold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: brandGold.withValues(alpha: 0.6), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Demo shortcuts — hidden in release builds
                      if (kDebugMode) ...[
                        Gap(28.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2122) : const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '💡 QUICK SIGN-IN PROFILES',
                                style: TextStyle(fontFamily: 'PlusJakartaSans',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: brandGold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Gap(12.h),
                              _buildDemoAccountButton(
                                'Amrit Maurya (Manager)',
                                'royaltandoor.owner@test.com',
                                isDark,
                              ),
                              Gap(8.h),
                              _buildDemoAccountButton(
                                'Priya Sharma (Cashier)',
                                'testcafe.owner@test.com',
                                isDark,
                              ),
                              Gap(8.h),
                              _buildDemoAccountButton(
                                'Rahul Verma (Server)',
                                'oceanbite.owner@test.com',
                                isDark,
                              ),
                              Gap(10.h),
                              Text(
                                'Click any profile above to instantly sign in',
                                style: TextStyle(fontFamily: 'PlusJakartaSans',
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      Gap(20.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          throw StateError('This is test exception');
                        },
                        icon: const Icon(Icons.bug_report_outlined, size: 16),
                        label: const Text('Verify Sentry Setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccountButton(String label, String email, bool isDark) {
    return SizedBox(
      height: 38.h,
      child: OutlinedButton(
        onPressed: () => _fillDemoCredentials(label, email),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'PlusJakartaSans',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14.sp),
          ],
        ),
      ),
    );
  }
}
