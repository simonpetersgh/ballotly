// lib/features/elections/presentation/screens/election_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

class ElectionDetailScreen extends ConsumerWidget {
  final String electionId;
  const ElectionDetailScreen({super.key, required this.electionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionAsync = ref.watch(electionProvider(electionId));
    final votedAsync = ref.watch(votedPositionsProvider(electionId));

    return electionAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (election) {
        final votedPositions = votedAsync.value ?? [];
        final allVoted =
            election.positions.isNotEmpty &&
            votedPositions.length == election.positions.length;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: ResponsiveScaffoldBody(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                election.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            StatusChip(status: election.status),
                          ],
                        ),
                        if (election.description != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            election.description!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _InfoItem(
                              icon: Icons.calendar_today,
                              label: 'Opens',
                              value: DateFormat(
                                'MMM d, yyyy',
                              ).format(election.startsAt.toLocal()),
                            ),
                            _InfoItem(
                              icon: Icons.event_busy,
                              label: 'Closes',
                              value: DateFormat(
                                'MMM d, yyyy',
                              ).format(election.endsAt.toLocal()),
                            ),
                            _InfoItem(
                              icon: Icons.ballot_outlined,
                              label: 'Positions',
                              value: '${election.positions.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Positions list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Positions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${votedPositions.length}/${election.positions.length} voted',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final position = election.positions[index];
                      final hasVoted = votedPositions.contains(position.id);
                      return _PositionCard(
                        position: position,
                        hasVoted: hasVoted,
                        electionId: electionId,
                        electionActive: election.isActive,
                      );
                    }, childCount: election.positions.length),
                  ),
                ),

                // CTA
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (!allVoted && election.isActive)
                          AppButton(
                            label: 'Start Voting',
                            icon: Icons.how_to_vote,
                            onPressed: () =>
                                context.go('/elections/$electionId/vote'),
                            width: double.infinity,
                          ),
                        if (allVoted || election.isClosed) ...[
                          AppButton(
                            label: 'View Results',
                            icon: Icons.bar_chart,
                            onPressed: () =>
                                context.go('/elections/$electionId/results'),
                            width: double.infinity,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PositionCard extends StatelessWidget {
  final PositionModel position;
  final bool hasVoted;
  final String electionId;
  final bool electionActive;

  const _PositionCard({
    required this.position,
    required this.hasVoted,
    required this.electionId,
    required this.electionActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasVoted
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasVoted ? Icons.check_circle : Icons.ballot_outlined,
                color: hasVoted ? AppTheme.success : AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${position.candidates.length} candidate${position.candidates.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (hasVoted)
              const Text(
                'Voted ✓',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (electionActive)
              const Text(
                'Pending',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
