
// lib/features/dashboard/presentation/screens/dashboard_screen.dart
//
// Unified dashboard for all logged-in users.
//
// ── My Elections ──────────────────────────────────────────────────────────────
//   Elections the current user created (created_by = user.id).
//   Full management access: edit, voters, results, status changes.
//
// ── Eligible Elections ────────────────────────────────────────────────────────
//   Elections where voters.email = user.email (published / active / closed).
//   Vote-only or results-only access depending on status.
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(currentUserProfileProvider);
    final createdAsync  = ref.watch(myCreatedElectionsProvider);
    final eligibleAsync = ref.watch(myElectionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: ResponsiveScaffoldBody(
        child: CustomScrollView(
          slivers: [
            // ── Welcome banner ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: profileAsync.when(
                    loading: () => const SizedBox(height: 52),
                    error: (_, __) => const Text('Welcome',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    data: (profile) => Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${profile?.fullName.split(' ').first ?? 'there'} 👋',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/admin/elections/new'),
                          icon: const Icon(Icons.add, size: 15,
                              color: Colors.white),
                          label: const Text('New Election',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── My Elections section ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Row(
                  children: [
                    const Text('My Elections',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Elections you created',
                      child: Icon(Icons.info_outline_rounded,
                          size: 14, color: AppTheme.textMuted),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.refresh(myCreatedElectionsProvider),
                      child: const Text('Refresh',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            createdAsync.when(
              loading: () => const SliverToBoxAdapter(child: LoadingState()),
              error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(
                      message: e.toString(),
                      onRetry: () =>
                          ref.refresh(myCreatedElectionsProvider))),
              data: (elections) {
                if (elections.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _EmptySection(
                        icon: Icons.ballot_outlined,
                        label: 'No elections created yet.',
                        action: TextButton.icon(
                          onPressed: () =>
                              context.go('/admin/elections/new'),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Create one'),
                        ),
                      ),
                    ),
                  );
                }
                final ordered = [
                  ...elections.where((e) => e.isActive),
                  ...elections.where((e) => e.isPublished),
                  ...elections.where((e) => e.isDraft),
                  ...elections.where((e) => e.isClosed),
                ];
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _MyElectionCard(election: ordered[i]),
                      childCount: ordered.length,
                    ),
                  ),
                );
              },
            ),

            // ── Eligible Elections section ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Text('Eligible Elections',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Elections you are registered to vote in',
                      child: Icon(Icons.info_outline_rounded,
                          size: 14, color: AppTheme.textMuted),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.refresh(myElectionsProvider),
                      child: const Text('Refresh',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            eligibleAsync.when(
              loading: () => const SliverToBoxAdapter(child: LoadingState()),
              error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(
                      message: e.toString(),
                      onRetry: () => ref.refresh(myElectionsProvider))),
              data: (elections) {
                if (elections.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _EmptySection(
                        icon: Icons.how_to_vote_outlined,
                        label:
                            'No eligible elections found for your email.',
                      ),
                    ),
                  );
                }

                final active    = elections.where((e) => e.isActive).toList();
                final published = elections.where((e) => e.isPublished).toList();
                final closed    = elections.where((e) => e.isClosed).toList();

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (active.isNotEmpty) ...[
                        _SectionLabel(
                            label: '🗳  Voting Open',
                            color: AppTheme.success),
                        const SizedBox(height: 8),
                        ...active.map((e) => _EligibleElectionCard(election: e)),
                        const SizedBox(height: 16),
                      ],
                      if (published.isNotEmpty) ...[
                        _SectionLabel(
                            label: '📢  Upcoming',
                            color: AppTheme.warning),
                        const SizedBox(height: 8),
                        ...published
                            .map((e) => _EligibleElectionCard(election: e)),
                        const SizedBox(height: 16),
                      ],
                      if (closed.isNotEmpty) ...[
                        _SectionLabel(
                            label: '✅  Ended',
                            color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        ...closed
                            .map((e) => _EligibleElectionCard(election: e)),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MY ELECTION CARD (management) ───────────────────────────────────────────

class _MyElectionCard extends ConsumerWidget {
  final ElectionModel election;
  const _MyElectionCard({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d · h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(election.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                StatusChip(status: election.status),
              ],
            ),

            if (election.description != null) ...[
              const SizedBox(height: 4),
              Text(election.description!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 10),

            // Verification mode badge
            Row(
              children: [
                _VerificationBadge(election: election),
                const SizedBox(width: 8),
                // Election code
                if (election.code != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 11,
                            color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Text(election.code!,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  '${election.positions.length} pos',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action row
            Row(
              children: [
                _ActionChip(
                  icon: Icons.settings_outlined,
                  label: 'Setup',
                  onTap: () => context.go(
                      '/admin/elections/${election.id}/setup'),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.people_outline,
                  label: 'Voters',
                  onTap: () => context.go(
                      '/admin/elections/${election.id}/voters'),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.bar_chart_rounded,
                  label: 'Results',
                  onTap: () => context.go(
                      '/admin/elections/${election.id}/results'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ELIGIBLE ELECTION CARD (vote / view) ────────────────────────────────────

class _EligibleElectionCard extends ConsumerWidget {
  final ElectionModel election;
  const _EligibleElectionCard({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d · h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(election.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                StatusChip(status: election.status),
              ],
            ),

            if (election.description != null) ...[
              const SizedBox(height: 4),
              Text(election.description!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 8),

            if (election.isPublished)
              _InfoRow(
                icon: Icons.schedule,
                text: 'Opens ${fmt.format(election.startsAt.toLocal())}',
                color: AppTheme.warning,
              ),
            if (election.isActive)
              _InfoRow(
                icon: Icons.timer_outlined,
                text: 'Closes ${fmt.format(election.endsAt.toLocal())}',
                color: AppTheme.success,
              ),
            if (election.isClosed)
              _InfoRow(
                icon: Icons.lock_outline,
                text: 'Ended ${fmt.format(election.endsAt.toLocal())}',
                color: AppTheme.textMuted,
              ),

            // Voting progress for active elections
            if (election.isActive) ...[
              const SizedBox(height: 8),
              _VotingProgress(election: election),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (election.isActive)
                  ElevatedButton.icon(
                    onPressed: () => _goToVote(context, ref, election),
                    icon: const Icon(Icons.how_to_vote, size: 15),
                    label: const Text('Vote Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                if (election.isClosed)
                  OutlinedButton.icon(
                    onPressed: () => context
                        .go('/results/${election.id}'),
                    icon: const Icon(Icons.bar_chart, size: 15),
                    label: const Text('View Results'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (election.isPublished)
                  Text(
                    '${election.positions.length} position${election.positions.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToVote(
      BuildContext context, WidgetRef ref, ElectionModel election) async {
    // Logged-in voter: look up voter record by account email, then go to
    // token confirmation before the ballot.
    final profile =
        await ref.read(currentUserProfileProvider.future);
    if (profile == null || !context.mounted) return;

    final voter = await ref
        .read(supabaseServiceProvider)
        .getVoterByEmail(
            electionId: election.id, email: profile.email);

    if (!context.mounted) return;

    if (voter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Your account email is not on the voter list for this election.')),
      );
      return;
    }

    // Navigate to token confirmation screen (in /elections shell)
    context.go(
      '/elections/${election.id}/confirm',
      extra: {'voter': voter},
    );
  }
}

// ─── VOTER TOKEN CONFIRMATION SCREEN ─────────────────────────────────────────
//
// Shown to logged-in voters before they reach the ballot.
// They've already authenticated via account login — we just need the token
// to confirm they are physically the right person.

class VoterTokenConfirmScreen extends ConsumerStatefulWidget {
  final String electionId;
  final VoterModel voter;

  const VoterTokenConfirmScreen({
    super.key,
    required this.electionId,
    required this.voter,
  });

  @override
  ConsumerState<VoterTokenConfirmScreen> createState() =>
      _VoterTokenConfirmScreenState();
}

class _VoterTokenConfirmScreenState
    extends ConsumerState<VoterTokenConfirmScreen> {
  final _primaryCtrl   = TextEditingController();
  final _secondaryCtrl = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(ElectionModel election) async {
    if (_primaryCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your primary token to continue.');
      return;
    }
    setState(() { _checking = true; _error = null; });
    try {
      final voter = await ref.read(supabaseServiceProvider).getVoterByToken(
            electionId: widget.electionId,
            email: widget.voter.email,
            primaryToken: _primaryCtrl.text.trim(),
            secondaryToken: election.secondaryTokenEnabled &&
                    _secondaryCtrl.text.trim().isNotEmpty
                ? _secondaryCtrl.text.trim()
                : null,
          );

      if (!mounted) return;

      if (voter == null) {
        setState(() => _error = 'Token does not match our records. '
            'Check with your organiser.');
        return;
      }

      context.go(
        '/elections/${widget.electionId}/vote',
        extra: {'voterId': voter.id},
      );
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final electionAsync = ref.watch(electionProvider(widget.electionId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: electionAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (election) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/dashboard'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),

                  // Election card
                  _EligibleElectionMiniCard(election: election),
                  const SizedBox(height: 28),

                  const Text('Confirm Your Identity',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  const Text(
                      'Enter the token(s) provided by your election organiser.',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5)),
                  const SizedBox(height: 24),

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

                  TextField(
                    controller: _primaryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary Token',
                      hintText: 'Enter your primary token',
                      prefixIcon: Icon(Icons.key_rounded, size: 18),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),

                  if (election.secondaryTokenEnabled) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _secondaryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Secondary Token',
                        hintText: 'Enter your secondary token',
                        prefixIcon:
                            Icon(Icons.vpn_key_outlined, size: 18),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checking
                          ? null
                          : () => _confirm(election),
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      child: _checking
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white))
                          : const Text('Continue to Ballot'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SMALL REUSABLE WIDGETS ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3));
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? action;
  const _EmptySection(
      {required this.icon, required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 4), action!],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.primary),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final ElectionModel election;
  const _VerificationBadge({required this.election});

  @override
  Widget build(BuildContext context) {
    final isOtp = election.isOtp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOtp
            ? AppTheme.accent.withOpacity(0.1)
            : AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOtp
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOtp ? Icons.mark_email_read_outlined : Icons.key_rounded,
            size: 11,
            color: isOtp ? AppTheme.accent : AppTheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isOtp ? 'OTP' : 'Token',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOtp ? AppTheme.accent : AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _VotingProgress extends ConsumerWidget {
  final ElectionModel election;
  const _VotingProgress({required this.election});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votedAsync = ref.watch(votedPositionsProvider(election.id));
    final total = election.positions.length;

    return votedAsync.when(
      data: (voted) {
        final progress = total > 0 ? voted.length / total : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${voted.length} of $total positions voted',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
                if (voted.length == total && total > 0)
                  const Row(children: [
                    Icon(Icons.check_circle,
                        size: 12, color: AppTheme.success),
                    SizedBox(width: 3),
                    Text('Complete',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.success),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EligibleElectionMiniCard extends StatelessWidget {
  final ElectionModel election;
  const _EligibleElectionMiniCard({required this.election});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.how_to_vote,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(election.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(
                  '${election.positions.length} position${election.positions.length == 1 ? '' : 's'}',
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
