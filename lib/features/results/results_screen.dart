// lib/features/results/presentation/screens/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class ResultsScreen extends ConsumerWidget {
  final String electionId;
  const ResultsScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionAsync = ref.watch(electionProvider(electionId));
    final resultsAsync = ref.watch(electionResultsProvider(electionId));
    final turnoutAsync = ref.watch(voterTurnoutProvider(electionId));
    final voterCountAsync = ref.watch(electionVoterCountProvider(electionId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: electionAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (election) => ResponsiveScaffoldBody(
          child: CustomScrollView(
            slivers: [
              // Header card
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
                        const SizedBox(height: 16),
                        turnoutAsync.when(
                          data: (turnout) => voterCountAsync.when(
                            data: (total) =>
                                _TurnoutTile(turnout: turnout, total: total),
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

              // Results list
              resultsAsync.when(
                loading: () =>
                    const SliverFillRemaining(child: LoadingState()),
                error: (e, _) => SliverFillRemaining(
                    child: ErrorState(message: e.toString())),
                data: (results) {
                  if (results.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'No results yet',
                        subtitle:
                            'Results will appear here once votes are cast.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PositionResult(result: results[i]),
                        childCount: results.length,
                      ),
                    ),
                  );
                },
              ),

              // Back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: AppButton(
                    label: 'Back to Elections',
                    outlined: true,
                    onPressed: () => context.go('/elections'),
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TURNOUT TILE ─────────────────────────────────────────────────────────────

class _TurnoutTile extends StatelessWidget {
  final int turnout;
  final int total;
  const _TurnoutTile({required this.turnout, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct =
        total > 0 ? (turnout / total * 100).toStringAsFixed(1) : '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$turnout / $total voted',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text('Voter turnout: $pct%',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── POSITION RESULT ─────────────────────────────────────────────────────────

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
            Text(result.positionTitle,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text('${result.totalVotes} total votes',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 16),

            // Desktop: 2-col grid of candidates
            // Mobile: stacked list
            if (isDesktop)
              _ResultsGrid(result: result)
            else
              ...result.candidates.asMap().entries.map(
                    (e) => _CandidateResultRow(
                      tally: e.value,
                      isWinner: e.key == 0 &&
                          result.totalVotes > 0 &&
                          e.value.voteCount > 0,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// Desktop 2-col grid for results
class _ResultsGrid extends StatelessWidget {
  final TallyResult result;
  const _ResultsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final candidates = result.candidates;
    final rows = <List<(int, CandidateTally)>>[];
    for (var i = 0; i < candidates.length; i += 2) {
      final end = i + 2 > candidates.length ? candidates.length : i + 2;
      rows.add(candidates.sublist(i, end).asMap().entries
          .map((e) => (i + e.key, e.value))
          .toList());
    }
    return Column(
      children: rows.map((row) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CandidateResultRow(
                tally: row[0].$2,
                isWinner: row[0].$1 == 0 &&
                    result.totalVotes > 0 &&
                    row[0].$2.voteCount > 0,
              ),
            ),
            if (row.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _CandidateResultRow(
                  tally: row[1].$2,
                  isWinner: row[1].$1 == 0 &&
                      result.totalVotes > 0 &&
                      row[1].$2.voteCount > 0,
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

// ─── CANDIDATE RESULT ROW ─────────────────────────────────────────────────────

class _CandidateResultRow extends StatelessWidget {
  final CandidateTally tally;
  final bool isWinner;

  const _CandidateResultRow(
      {required this.tally, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: isWinner
          ? BoxDecoration(
              color: AppTheme.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2)),
            )
          : null,
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
                    if (isWinner)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.emoji_events,
                            size: 15,
                            color: Color(0xFFFFB800)),
                      ),
                    Expanded(
                      child: Text(
                        tally.candidateName,
                        style: TextStyle(
                          fontWeight: isWinner
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${tally.voteCount} (${tally.percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isWinner ? FontWeight.w700 : FontWeight.w400,
                  color: isWinner
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tally.percentage / 100,
              minHeight: 7,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(
                isWinner
                    ? AppTheme.primary
                    : AppTheme.textMuted.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
