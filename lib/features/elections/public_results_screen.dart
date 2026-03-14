

// lib/features/results/presentation/screens/public_results_screen.dart
//
// Accessible at /results/:electionId — no auth required.
// Can be reached from:
//   - Guest ballot completion screen
//   - Landing page "View Results" button (via code lookup)
//   - Direct link sharing
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

class PublicResultsScreen extends ConsumerWidget {
  final String electionId;
  const PublicResultsScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionAsync = ref.watch(electionProvider(electionId));
    final resultsAsync = ref.watch(publicElectionResultsProvider(electionId));
    final turnoutAsync = ref.watch(voterTurnoutProvider(electionId));
    final voterCountAsync = ref.watch(electionVoterCountProvider(electionId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ── Nav bar ─────────────────────────────────────────────────────────
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
                  child: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                const Text('Election Results',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: electionAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: 'Could not load election results.',
                onRetry: () => ref.refresh(electionProvider(electionId)),
              ),
              data: (election) {
                // Not yet closed — show appropriate state
                if (!election.isClosed && !election.isActive) {
                  return _NotReadyState(election: election);
                }

                return ResponsiveScaffoldBody(
                  child: CustomScrollView(
                    slivers: [
                      // ── Header card ────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChipLight(status: election.status),
                                const SizedBox(height: 10),
                                Text(election.title,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                if (election.description != null &&
                                    election.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(election.description!,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.4)),
                                ],
                                const SizedBox(height: 16),
                                // Turnout
                                turnoutAsync.when(
                                  data: (turnout) => voterCountAsync.when(
                                    data: (total) => _TurnoutBar(
                                        turnout: turnout, total: total),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Live indicator if still active ─────────────────────
                      if (election.isActive)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _LiveBanner(),
                          ),
                        ),

                      // ── Results ────────────────────────────────────────────
                      resultsAsync.when(
                        loading: () => const SliverFillRemaining(
                            child: LoadingState()),
                        error: (e, _) => SliverFillRemaining(
                            child: ErrorState(message: e.toString())),
                        data: (results) {
                          if (results.isEmpty) {
                            return const SliverFillRemaining(
                              child: EmptyState(
                                icon: Icons.bar_chart_outlined,
                                title: 'No votes yet',
                                subtitle:
                                    'Results will appear as votes are cast.',
                              ),
                            );
                          }
                          return SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) =>
                                    _PositionResult(result: results[i]),
                                childCount: results.length,
                              ),
                            ),
                          );
                        },
                      ),

                      // ── Footer ─────────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          child: Column(
                            children: [
                              AppButton(
                                label: 'Back to Home',
                                outlined: true,
                                onPressed: () => context.go('/'),
                                width: double.infinity,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Results provided by EVoteHub · evotehub.app',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NOT READY STATE ──────────────────────────────────────────────────────────

class _NotReadyState extends StatelessWidget {
  final ElectionModel election;
  const _NotReadyState({required this.election});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                election.isDraft
                    ? 'Election not published'
                    : 'Results not available yet',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                election.isPublished
                    ? 'This election is scheduled but voting hasn\'t started. '
                      'Results will be available once voting closes.'
                    : 'Results will be published when this election closes.',
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Back to Home',
                outlined: true,
                onPressed: () => context.go('/'),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TURNOUT BAR ──────────────────────────────────────────────────────────────

class _TurnoutBar extends StatelessWidget {
  final int turnout;
  final int total;
  const _TurnoutBar({required this.turnout, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (turnout / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$turnout of $total voted',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text('${pct.toStringAsFixed(1)}% turnout',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? turnout / total : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIVE BANNER ─────────────────────────────────────────────────────────────

class _LiveBanner extends StatelessWidget {
  const _LiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppTheme.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          const Text('Voting is still open — results update in real time.',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── POSITION RESULT ──────────────────────────────────────────────────────────

class _PositionResult extends StatelessWidget {
  final TallyResult result;
  const _PositionResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(result.positionTitle,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                ),
                Text('${result.totalVotes} vote${result.totalVotes == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              _ResultsGrid(result: result)
            else
              ...result.candidates.asMap().entries.map(
                    (e) => _CandidateBar(
                      tally: e.value,
                      isWinner: e.key == 0 &&
                          result.totalVotes > 0 &&
                          e.value.voteCount > 0,
                      totalVotes: result.totalVotes,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── RESULTS GRID (desktop 2-col) ─────────────────────────────────────────────

class _ResultsGrid extends StatelessWidget {
  final TallyResult result;
  const _ResultsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final candidates = result.candidates;
    final rows = <List<(int, CandidateTally)>>[];
    for (var i = 0; i < candidates.length; i += 2) {
      final end =
          i + 2 > candidates.length ? candidates.length : i + 2;
      rows.add(candidates
          .sublist(i, end)
          .asMap()
          .entries
          .map((e) => (i + e.key, e.value))
          .toList());
    }
    return Column(
      children: rows.map((row) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CandidateBar(
                tally: row[0].$2,
                isWinner: row[0].$1 == 0 &&
                    result.totalVotes > 0 &&
                    row[0].$2.voteCount > 0,
                totalVotes: result.totalVotes,
              ),
            ),
            if (row.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _CandidateBar(
                  tally: row[1].$2,
                  isWinner: row[1].$1 == 0 &&
                      result.totalVotes > 0 &&
                      row[1].$2.voteCount > 0,
                  totalVotes: result.totalVotes,
                ),
              ),
            ] else
              const Expanded(child: SizedBox()),
          ],
        );
      }).toList(),
    );
  }
}

// ─── CANDIDATE BAR ────────────────────────────────────────────────────────────

class _CandidateBar extends StatelessWidget {
  final CandidateTally tally;
  final bool isWinner;
  final int totalVotes;

  const _CandidateBar({
    required this.tally,
    required this.isWinner,
    required this.totalVotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: isWinner
          ? BoxDecoration(
              color: AppTheme.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            )
          : BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CandidateAvatar(
                name: tally.candidateName,
                photoUrl: tally.photoUrl,
                ballotNumber: tally.ballotNumber,
                size: 40,
                color: isWinner ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    if (isWinner && totalVotes > 0)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.emoji_events_rounded,
                            size: 16, color: Color(0xFFFFB800)),
                      ),
                    Expanded(
                      child: Text(tally.candidateName,
                          style: TextStyle(
                              fontWeight: isWinner
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tally.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isWinner
                            ? AppTheme.primary
                            : AppTheme.textSecondary),
                  ),
                  Text('${tally.voteCount} vote${tally.voteCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tally.percentage / 100,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(
                isWinner
                    ? AppTheme.primary
                    : AppTheme.textMuted.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
