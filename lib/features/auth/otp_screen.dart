// lib/features/auth/presentation/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/shared_widgets.dart';
import 'auth_widgets.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String? fullName;
  final String mode; // voter_register | voter_login | organiser_register

  const OtpScreen({
    super.key,
    required this.email,
    this.fullName,
    required this.mode,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;
  String? _error;

  bool get _isVoterRegister => widget.mode == 'voter_register';
  bool get _isOrganiserRegister => widget.mode == 'organiser_register';
  bool get _isRegister => _isVoterRegister || _isOrganiserRegister;

  String get _title {
    if (_isRegister) return 'Verify your email';
    return 'Check your email';
  }

  String get _subtitle {
    if (_isRegister) {
      return 'Enter the 6-digit code sent to ${widget.email} to complete your registration.';
    }
    return 'Enter the 6-digit code sent to ${widget.email}.';
  }

  String get _buttonLabel {
    if (_isVoterRegister) return 'Create Voter Account';
    if (_isOrganiserRegister) return 'Confirm & Activate';
    return 'Sign In';
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
  if (_otpCode.length < 6) {
    setState(() => _error = 'Please enter the complete 6-digit code.');
    return;
  }
  setState(() { _loading = true; _error = null; });
  try {
    if (_isOrganiserRegister) {
      await ref.read(supabaseServiceProvider).verifyOrganiserOtp(
        email: widget.email,
        token: _otpCode,
      );
      // Organiser register — create profile then go to admin
      if (widget.fullName != null) {
        await ref.read(supabaseServiceProvider).createUserProfile(
          fullName: widget.fullName!,
          accountType: SupabaseConstants.accountTypeOrganiser,
        );
      }
      if (mounted) context.go('/admin');
    } else {
      // Voter — verify then check if profile exists
      await ref.read(supabaseServiceProvider).verifyOtp(
        email: widget.email,
        token: _otpCode,
      );
      final profile = await ref
          .read(supabaseServiceProvider)
          .getCurrentUserProfile();
      if (mounted) {
        // Profile exists → returning user → go straight home
        // No profile → new user → collect their name first
        profile != null
            ? context.go('/elections')
            : context.go('/voter/profile');
      }
    }
  } catch (e) {
    setState(() {
      _error = 'Invalid or expired code. Please try again.';
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    });
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      if (_isOrganiserRegister) {
        throw Exception('Please go back and sign up again to resend.');
      }
      await ref.read(supabaseServiceProvider).voterSendOtp(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new code has been sent to your email.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _resend2() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final svc = ref.read(supabaseServiceProvider);
      if (_isVoterRegister) {
        await svc.voterSignUp(
          email: widget.email,
          fullName: widget.fullName ?? '',
        );
      } else if (_isOrganiserRegister) {
        // Re-send not straightforward for password signup — just inform user
        throw Exception('Please go back and sign up again to resend.');
      } else {
        await svc.voterSignIn(widget.email);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new code has been sent to your email.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted)
        setState(() {
          _resending = false;
        });
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (_otpCode.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthLogo(),
          const SizedBox(height: 40),

          Text(
            _title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          if (_error != null) AuthErrorBanner(message: _error!),

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onDigitEntered(i, v),
              ),
            ),
          ),

          const SizedBox(height: 32),

          AppButton(
            label: _buttonLabel,
            onPressed: _verify,
            loading: _loading,
            width: double.infinity,
          ),

          const SizedBox(height: 20),

          if (!_isOrganiserRegister)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive a code? ",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                GestureDetector(
                  onTap: _resending ? null : _resend,
                  child: Text(
                    _resending ? 'Sending...' : 'Resend',
                    style: TextStyle(
                      color: _resending ? AppTheme.textMuted : AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          Center(
            child: GestureDetector(
              onTap: () => context.go(
                _isOrganiserRegister ? '/organiser/register' : '/voter/login',
              ),
              child: const Text(
                'Use a different email',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppTheme.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
