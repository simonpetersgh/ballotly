
// lib/features/guest/presentation/screens/guest_otp_verify_screen.dart
//
// Reached from GuestEntryScreen when user chooses the OTP path.
// Shows election summary card + 6-digit OTP input.
// On success routes to the guest ballot.
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/core/providers/providers.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class GuestOtpVerifyScreen extends ConsumerStatefulWidget {
  final ElectionModel election;
  final VoterModel voter;
  final String email;

  const GuestOtpVerifyScreen({
    super.key,
    required this.election,
    required this.voter,
    required this.email,
  });

  @override
  ConsumerState<GuestOtpVerifyScreen> createState() =>
      _GuestOtpVerifyScreenState();
}

class _GuestOtpVerifyScreenState
    extends ConsumerState<GuestOtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  bool _resent = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).verifyOtp(
            email: widget.email,
            token: token,
          );
      if (!mounted) return;
      context.go(
        '/guest/${widget.election.id}',
        extra: {'voterId': widget.voter.id, 'email': widget.voter.email},
      );
    } catch (e) {
      setState(() => _error =
          'Invalid or expired code. Request a new one and try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _resent = false; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).voterSignIn(widget.email);
      setState(() => _resent = true);
    } catch (_) {
      try {
        await ref.read(supabaseServiceProvider).voterSignUp(
              email: widget.email,
              fullName: widget.voter.fullName,
            );
        setState(() => _resent = true);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

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
                      context.canPop() ? context.pop() : context.go('/guest'),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent]),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text('Email Verification',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Election summary card
                        _ElectionSummaryCard(election: widget.election),
                        const SizedBox(height: 28),

                        const Text('Check Your Email',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.5),
                            children: [
                              const TextSpan(
                                  text: 'We sent a 6-digit code to '),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary),
                              ),
                              const TextSpan(text: '. Enter it below.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.danger.withOpacity(0.2)),
                            ),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.danger, fontSize: 13)),
                          ),
                        ],

                        // OTP input
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 12,
                              color: AppTheme.textPrimary),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                                fontSize: 30,
                                letterSpacing: 10,
                                color:
                                    AppTheme.textMuted.withOpacity(0.35)),
                          ),
                          onChanged: (_) {
                            if (_error != null)
                              setState(() => _error = null);
                          },
                          onSubmitted: (_) => _verify(),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _verifying ? null : _verify,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14)),
                            child: _verifying
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white))
                                : const Text('Verify & Open Ballot'),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: _resent
                              ? const Text('Code resent!',
                                  style: TextStyle(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w600))
                              : TextButton(
                                  onPressed:
                                      _resending ? null : _resend,
                                  child: const Text(
                                      "Didn't get it? Resend code",
                                      style: TextStyle(
                                          color: AppTheme.textSecondary)),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ELECTION SUMMARY CARD ────────────────────────────────────────────────────

class _ElectionSummaryCard extends StatelessWidget {
  final ElectionModel election;
  const _ElectionSummaryCard({required this.election});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.how_to_vote,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(election.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(
                  '${election.positions.length} position${election.positions.length == 1 ? '' : 's'} · ${election.isActive ? 'Voting open' : election.isPublished ? 'Not yet open' : 'Closed'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          StatusChip(status: election.status),
        ],
      ),
    );
  }
}
