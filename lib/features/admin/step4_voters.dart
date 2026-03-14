// step4_voters.dart
//
// PREMIUM FEATURES in this step (guards commented out):
//   • Voter count exceeding freeVoterLimit — shows info banner, does NOT block
//   • Primary token field (always shown and writable — token logic is free)
//   • Secondary token field — shown only when election.secondaryTokenEnabled = true
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

class Step4Voters extends ConsumerStatefulWidget {
  final String electionId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step4Voters({
    super.key,
    required this.electionId,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<Step4Voters> createState() => _Step4VotersState();
}

class _Step4VotersState extends ConsumerState<Step4Voters> {
  final _emailCtrl     = TextEditingController();
  final _nameCtrl      = TextEditingController();
  final _primaryCtrl   = TextEditingController();
  final _secondaryCtrl = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _addVoter(ElectionModel election) async {
    final email = _emailCtrl.text.trim();
    final name  = _nameCtrl.text.trim();
    if (email.isEmpty || name.isEmpty) {
      setState(() => _error = 'Email and name are required.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    // ── PREMIUM GATE — voter limit ─────────────────────────────────────────
    // Uncomment the block below to enforce the free tier cap.
    // final voters = await ref.read(electionVotersProvider(widget.electionId).future);
    // if (!election.isPaid && voters.length >= SupabaseConstants.freeVoterLimit) {
    //   setState(() => _error =
    //       'Free elections are limited to ${SupabaseConstants.freeVoterLimit} voters. '
    //       'Upgrade this election to add more.');
    //   return;
    // }

    setState(() { _adding = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).addVoter(
        electionId: widget.electionId,
        email: email,
        fullName: name,
        primaryToken: _primaryCtrl.text.trim().isEmpty
            ? null
            : _primaryCtrl.text.trim(),
        secondaryToken: election.secondaryTokenEnabled &&
                _secondaryCtrl.text.trim().isNotEmpty
            ? _secondaryCtrl.text.trim()
            : null,
      );
      _emailCtrl.clear();
      _nameCtrl.clear();
      _primaryCtrl.clear();
      _secondaryCtrl.clear();
      ref.refresh(electionVotersProvider(widget.electionId));
    } catch (e) {
      setState(() {
        _error = e.toString().contains('duplicate')
            ? 'This email is already on the voter list.'
            : 'Failed to add voter. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeVoter(String voterId) async {
    await ref.read(supabaseServiceProvider).removeVoter(voterId);
    ref.refresh(electionVotersProvider(widget.electionId));
  }

  @override
  Widget build(BuildContext context) {
    final votersAsync  = ref.watch(electionVotersProvider(widget.electionId));
    final electionAsync = ref.watch(electionProvider(widget.electionId));

    return Column(children: [
      Expanded(
        child: ResponsiveScaffoldBody(
          maxWidth: Responsive.formMax,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: electionAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: e.toString()),
              data: (election) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ───────────────────────────────────────────────
                  Row(children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eligible Voters',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text(
                              'Add voters who are eligible to vote in this election.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    votersAsync.when(
                      data: (voters) => _VoterCountBadge(
                          count: voters.length,
                          isPaid: election.isPaid),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Voter limit banner (informational, never blocks) ──────
                  votersAsync.when(
                    data: (voters) =>
                        voters.length >= SupabaseConstants.freeVoterLimit &&
                                !election.isPaid
                            ? _LimitBanner(count: voters.length)
                            : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // ── Verification mode info chip ───────────────────────────
                  _VerificationInfo(election: election),

                  const SizedBox(height: 20),

                  // ── Add voter form ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Voter',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 14),

                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.danger, fontSize: 13)),
                          ),

                        // Name + email row
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Full Name', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email', isDense: true),
                            ),
                          ),
                        ]),

                        // Token fields
                        if (election.verificationMode ==
                            SupabaseConstants.verificationManual) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _primaryCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Primary Token',
                                    hintText: 'e.g. student ID',
                                    isDense: true),
                              ),
                            ),
                            if (election.secondaryTokenEnabled) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _secondaryCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Secondary Token',
                                      hintText: 'e.g. date of birth',
                                      isDense: true),
                                ),
                              ),
                            ],
                          ]),
                        ],

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _adding
                                ? null
                                : () => _addVoter(election),
                            icon: _adding
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.person_add, size: 16),
                            label: Text(_adding ? 'Adding...' : 'Add Voter'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Voters list ──────────────────────────────────────────
                  votersAsync.when(
                    loading: () => const LoadingState(),
                    error: (e, _) => ErrorState(message: e.toString()),
                    data: (voters) {
                      if (voters.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border)),
                          child: const Column(children: [
                            Icon(Icons.people_outline,
                                size: 36, color: AppTheme.textMuted),
                            SizedBox(height: 8),
                            Text('No voters added yet.',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ]),
                        );
                      }
                      return Column(
                        children: voters
                            .map((v) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.primary.withOpacity(0.1),
                                      child: Text(
                                        v.fullName.isNotEmpty
                                            ? v.fullName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    title: Text(v.fullName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(v.email,
                                            style: const TextStyle(fontSize: 12)),
                                        if (v.primaryToken != null)
                                          Text('Token: ${v.primaryToken}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textMuted)),
                                      ],
                                    ),
                                    isThreeLine: v.primaryToken != null,
                                    trailing: IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppTheme.danger,
                                          size: 20),
                                      onPressed: () => _removeVoter(v.id),
                                    ),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),

      StepNavBar(
        onBack: widget.onBack,
        onNext: widget.onNext,
        nextLabel: 'Continue to Review',
      ),
    ]);
  }
}

// ─── VOTER COUNT BADGE ────────────────────────────────────────────────────────

class _VoterCountBadge extends StatelessWidget {
  final int count;
  final bool isPaid;
  const _VoterCountBadge({required this.count, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final overLimit =
        count >= SupabaseConstants.freeVoterLimit && !isPaid;
    final color = overLimit ? AppTheme.warning : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: overLimit
            ? Border.all(color: AppTheme.warning.withOpacity(0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (overLimit)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child:
                  Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.warning),
            ),
          Text('$count added',
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700)),
          if (!isPaid) ...[
            Text(' / ${SupabaseConstants.freeVoterLimit}',
                style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

// ─── LIMIT BANNER (informational — never blocks) ──────────────────────────────

class _LimitBanner extends StatelessWidget {
  final int count;
  const _LimitBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count voters added — above the free limit of ${SupabaseConstants.freeVoterLimit}.',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                const Text(
                  'You can keep adding voters now. Upgrade this election to '
                  'a paid plan before publishing to ensure all voters can access the ballot.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4),
                ),
                // ── PREMIUM GATE — upgrade CTA (uncomment when ready) ──────
                // const SizedBox(height: 8),
                // ElevatedButton.icon(
                //   onPressed: () { /* navigate to upgrade flow */ },
                //   icon: const Icon(Icons.upgrade, size: 14),
                //   label: const Text('Upgrade Election'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppTheme.warning,
                //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                //     textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VERIFICATION INFO CHIP ───────────────────────────────────────────────────

class _VerificationInfo extends StatelessWidget {
  final ElectionModel election;
  const _VerificationInfo({required this.election});

  @override
  Widget build(BuildContext context) {
    final isOtp = election.isOtp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOtp
            ? AppTheme.accent.withOpacity(0.06)
            : AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOtp
              ? AppTheme.accent.withOpacity(0.25)
              : AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOtp
                ? Icons.mark_email_read_outlined
                : Icons.key_rounded,
            size: 15,
            color: isOtp ? AppTheme.accent : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOtp
                  ? 'This election uses OTP verification — voters will '
                      'receive an email code. You still need to add their '
                      'email addresses below.'
                  : election.secondaryTokenEnabled
                      ? 'Token verification is on with a secondary token. '
                          'Add primary and secondary tokens for each voter below.'
                      : 'Token verification is on. '
                          'Add a primary token for each voter below.',
              style: TextStyle(
                  fontSize: 12,
                  color: isOtp ? AppTheme.accent : AppTheme.primary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
