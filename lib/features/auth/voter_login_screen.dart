// lib/features/auth/presentation/screens/voter_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/shared_widgets.dart';
import 'auth_widgets.dart';

class VoterLoginScreen extends ConsumerStatefulWidget {
  const VoterLoginScreen({super.key});

  @override
  ConsumerState<VoterLoginScreen> createState() => _VoterLoginScreenState();
}

class _VoterLoginScreenState extends ConsumerState<VoterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).voterSignIn(
        _emailController.text.trim(),
      );
      if (mounted) {
        context.go(
          '/otp?email=${Uri.encodeComponent(_emailController.text.trim())}'
          '&mode=voter_login',
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthLogo(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Voter Sign In',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email to receive a one-time sign-in code.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          if (_error != null) AuthErrorBanner(message: _error!),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter your registered email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Send Sign-In Code',
                  onPressed: _sendOtp,
                  loading: _loading,
                  width: double.infinity,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ", style: TextStyle(color: AppTheme.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/voter/register'),
                child: const Text('Register', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
