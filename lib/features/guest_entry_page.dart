// lib/features/guest/presentation/screens/guest_entry_screen.dart
//
// Default form: manual verification (code + email + primary token + secondary token)
// Toggle below Continue button: "Use OTP verification instead"
// OTP form: code + email only → checks election supports OTP → routes to GuestOtpVerifyScreen.
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';


enum _VerifyMethod { manual, otp }

class GuestEntryScreen extends ConsumerStatefulWidget {
  const GuestEntryScreen({super.key});

  @override
  ConsumerState<GuestEntryScreen> createState() => _GuestEntryScreenState();
}

class _GuestEntryScreenState extends ConsumerState<GuestEntryScreen> {
  _VerifyMethod _method = _VerifyMethod.manual;

  // Shared
  final _codeCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Manual-only
  final _primaryCtrl   = TextEditingController();
  final _secondaryCtrl = TextEditingController();

  bool _checking = false;

  String? _codeError;
  String? _emailError;
  String? _primaryError;
  String? _generalError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  void _switchMethod(_VerifyMethod m) {
    setState(() {
      _method = m;
      _codeError = _emailError = _primaryError = _generalError = null;
    });
  }

  // ── Manual submit ────────────────────────────────────────────────────────────

  Future<void> _submitManual() async {
    final code    = _codeCtrl.text.trim();
    final email   = _emailCtrl.text.trim().toLowerCase();
    final primary = _primaryCtrl.text.trim();

    String? ce, ee, pe;
    if (code.isEmpty)                          ce = 'Enter the election code.';
    if (email.isEmpty || !email.contains('@')) ee = 'Enter a valid email.';
    if (primary.isEmpty)                       pe = 'Enter your primary token.';
    if (ce != null || ee != null || pe != null) {
      setState(() { _codeError = ce; _emailError = ee; _primaryError = pe; });
      return;
    }

    setState(() { _checking = true; _generalError = null; });
    try {
      final election =
          await ref.read(supabaseServiceProvider).getElectionByCode(code);
      if (election == null) {
        setState(() =>
            _codeError = 'No election found with this code. Check with your organiser.');
        return;
      }

      final secondary = election.secondaryTokenEnabled &&
              _secondaryCtrl.text.trim().isNotEmpty
          ? _secondaryCtrl.text.trim()
          : null;

      final voter = await ref.read(supabaseServiceProvider).getVoterByToken(
            electionId: election.id,
            email: email,
            primaryToken: primary,
            secondaryToken: secondary,
          );

      if (voter == null) {
        setState(() => _generalError =
            'Your details do not match our records. '
            'Check your email and token(s) or contact your organiser.');
        return;
      }

      if (!mounted) return;
      context.go(
        '/guest/${election.id}',
        extra: {'voterId': voter.id, 'email': voter.email},
      );
    } catch (e) {
      setState(() => _generalError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  // ── OTP submit ───────────────────────────────────────────────────────────────

  Future<void> _submitOtp() async {
    final code  = _codeCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();

    String? ce, ee;
    if (code.isEmpty)                          ce = 'Enter the election code.';
    if (email.isEmpty || !email.contains('@')) ee = 'Enter a valid email.';
    if (ce != null || ee != null) {
      setState(() { _codeError = ce; _emailError = ee; });
      return;
    }

    setState(() { _checking = true; _generalError = null; });
    try {
      final election =
          await ref.read(supabaseServiceProvider).getElectionByCode(code);
      if (election == null) {
        setState(() =>
            _codeError = 'No election found with this code. Check with your organiser.');
        return;
      }

      if (!election.isOtp) {
        setState(() => _generalError =
            'This election does not support OTP verification. '
            'Use token verification instead.');
        return;
      }

      final voter = await ref.read(supabaseServiceProvider).getVoterByEmail(
            electionId: election.id,
            email: email,
          );
      if (voter == null) {
        setState(() => _emailError =
            'This email is not on the voter list for "${election.title}".');
        return;
      }

      try {
        await ref.read(supabaseServiceProvider).voterSignIn(email);
      } catch (e) {
        if (e.toString().contains('No account found')) {
          await ref.read(supabaseServiceProvider).voterSignUp(
                email: email, fullName: voter.fullName);
        } else rethrow;
      }

      if (!mounted) return;
      context.go('/guest/otp-verify',
          extra: {'election': election, 'voter': voter, 'email': email});
    } catch (e) {
      setState(() => _generalError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Nav bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppTheme.textPrimary,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent]),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.how_to_vote,
                      color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                const Text('Vote as Guest',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _method == _VerifyMethod.manual
                        ? _buildManualForm()
                        : _buildOtpForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Manual form ──────────────────────────────────────────────────────────────

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Access the Ballot',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text(
            'Enter your election code, email and the token(s) provided by your organiser.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 28),

        const _FieldLabel(text: 'Election Code'),
        const SizedBox(height: 6),
        _CodeField(controller: _codeCtrl, errorText: _codeError,
            onChanged: (_) { if (_codeError != null) setState(() => _codeError = null); }),

        const SizedBox(height: 18),
        const _FieldLabel(text: 'Email Address'),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 19),
            errorText: _emailError,
          ),
          onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
        ),

        const SizedBox(height: 18),
        const _FieldLabel(text: 'Primary Token'),
        const SizedBox(height: 6),
        TextField(
          controller: _primaryCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. your ID or membership number',
            prefixIcon: const Icon(Icons.key_rounded, size: 19),
            errorText: _primaryError,
          ),
          onChanged: (_) { if (_primaryError != null) setState(() => _primaryError = null); },
        ),

        const SizedBox(height: 18),
        const _FieldLabel(text: 'Secondary Token  (if required by organiser)'),
        const SizedBox(height: 6),
        TextField(
          controller: _secondaryCtrl,
          decoration: const InputDecoration(
            hintText: 'Leave blank if not required',
            prefixIcon: Icon(Icons.vpn_key_outlined, size: 19),
          ),
        ),

        if (_generalError != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: _generalError!),
        ],

        const SizedBox(height: 24),
        _SubmitButton(loading: _checking, label: 'Continue', onPressed: _submitManual),

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _switchMethod(_VerifyMethod.otp),
            child: const Text('Use OTP verification instead →',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ),

        const SizedBox(height: 24),
        const _HelpNote(
            text: 'Your code, email and token(s) must match exactly what your '
                'organiser registered. Contact them if you need help.'),
      ],
    );
  }

  // ── OTP form ─────────────────────────────────────────────────────────────────

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('OTP Verification',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text(
            'Enter the election code and your email. A one-time code '
            'will be sent to verify your identity.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 28),

        const _FieldLabel(text: 'Election Code'),
        const SizedBox(height: 6),
        _CodeField(controller: _codeCtrl, errorText: _codeError,
            onChanged: (_) { if (_codeError != null) setState(() => _codeError = null); }),

        const SizedBox(height: 18),
        const _FieldLabel(text: 'Email Address'),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 19),
            errorText: _emailError,
          ),
          onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
          onSubmitted: (_) => _submitOtp(),
        ),

        if (_generalError != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: _generalError!),
        ],

        const SizedBox(height: 24),
        _SubmitButton(
            loading: _checking,
            label: 'Send Verification Code',
            onPressed: _submitOtp),

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _switchMethod(_VerifyMethod.manual),
            child: const Text('← Back to token verification',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ),

        const SizedBox(height: 24),
        const _HelpNote(
            text: 'OTP verification is only available for elections that '
                'support it. If blocked, switch back to token verification.'),
      ],
    );
  }
}

// ─── SHARED FIELD WIDGETS ────────────────────────────────────────────────────

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final void Function(String) onChanged;
  const _CodeField({required this.controller, this.errorText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800,
          letterSpacing: 4, color: AppTheme.textPrimary),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'ABCD1234',
        hintStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400,
            letterSpacing: 4, color: AppTheme.textMuted.withOpacity(0.5)),
        errorText: errorText,
      ),
      onChanged: onChanged,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onPressed;
  const _SubmitButton(
      {required this.loading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14)),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
        ),
        child: Text(message,
            style: const TextStyle(color: AppTheme.danger, fontSize: 13)));
}

class _HelpNote extends StatelessWidget {
  final String text;
  const _HelpNote({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5)),
            ),
          ],
        ));
}
