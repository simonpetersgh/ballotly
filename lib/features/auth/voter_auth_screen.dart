// lib/features/auth/presentation/screens/voter_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/shared_widgets.dart';
import 'auth_widgets.dart';

class VoterAuthScreen extends ConsumerStatefulWidget {
  const VoterAuthScreen({super.key});

  @override
  ConsumerState<VoterAuthScreen> createState() => _VoterAuthScreenState();
}

class _VoterAuthScreenState extends ConsumerState<VoterAuthScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).voterSendOtp(
        _emailCtrl.text.trim().toLowerCase(),
      );
      if (mounted) {
        context.go(
          '/otp?email=${Uri.encodeComponent(_emailCtrl.text.trim().toLowerCase())}&mode=voter',
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthLogo(),
            const SizedBox(height: 40),
            const Text(
              'Sign in to vote',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email — we\'ll send you a code to sign in.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (_error != null) AuthErrorBanner(message: _error!),
            AppTextField(
              label: 'Email address',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Send Code',
              icon: Icons.send,
              onPressed: _sendOtp,
              loading: _loading,
              width: double.infinity,
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/organiser/login'),
                child: const Text(
                  'Signing in as an organiser?',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}