// lib/features/auth/presentation/screens/voter_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/shared_widgets.dart';
import 'auth_widgets.dart';

class VoterRegisterScreen extends ConsumerStatefulWidget {
  const VoterRegisterScreen({super.key});

  @override
  ConsumerState<VoterRegisterScreen> createState() => _VoterRegisterScreenState();
}

class _VoterRegisterScreenState extends ConsumerState<VoterRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).voterSignUp(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );
      if (mounted) {
        context.go(
          '/otp?email=${Uri.encodeComponent(_emailController.text.trim())}'
          '&name=${Uri.encodeComponent(_fullNameController.text.trim())}'
          '&mode=voter_register',
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
            onPressed: () => context.go('/voter/login'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to sign in'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary, padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Voter Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your name and email. We'll send a verification code.",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          if (_error != null) AuthErrorBanner(message: _error!),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _fullNameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter your email',
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
                  label: 'Send Verification Code',
                  onPressed: _register,
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
              const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/voter/login'),
                child: const Text('Sign in', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
