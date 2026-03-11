// lib/features/elections/presentation/screens/elections_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class ElectionsScreen extends ConsumerWidget {
  const ElectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionsAsync = ref.watch(myElectionsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: ResponsiveScaffoldBody(
        child: CustomScrollView(
          slivers: [
            // Welcome banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
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
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${profile?.fullName!.split(' ').first ?? 'Voter'} 👋',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your elections are listed below.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 52),
                error: (_, __) => const Text('Welcome', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ),
          ),

          electionsAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingState()),
            error: (e, _) => SliverFillRemaining(
              child: ErrorState(message: 'Could not load elections.', onRetry: () => ref.refresh(myElectionsProvider)),
            ),
            data: (elections) {
              if (elections.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.how_to_vote_outlined,
                    title: 'No elections yet',
                    subtitle: 'You\'ll see elections here once you\'ve been added to one.',
                  ),
                );
              }

              // Group by status
              final active = elections.where((e) => e.isActive).toList();
              final published = elections.where((e) => e.isPublished).toList();
              final closed = elections.where((e) => e.isClosed).toList();

              final isDesktop = Responsive.isDesktop(context);
              Widget cardList(List<ElectionModel> elections) {
                if (isDesktop && elections.length > 1) {
                  // 2-column grid
                  final rows = <Widget>[];
                  for (var i = 0; i < elections.length; i += 2) {
                    final right = i + 1 < elections.length
                        ? Expanded(child: _ElectionCard(election: elections[i + 1], ref: ref))
                        : const Expanded(child: SizedBox());
                    rows.add(Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ElectionCard(election: elections[i], ref: ref)),
                        const SizedBox(width: 12),
                        right,
                      ],
                    ));
                  }
                  return Column(children: rows);
                }
                return Column(children: elections.map((e) => _ElectionCard(election: e, ref: ref)).toList());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (active.isNotEmpty) ...[
                      _SectionLabel(label: '🗳  Voting Open', color: AppTheme.success),
                      const SizedBox(height: 10),
                      cardList(active),
                      const SizedBox(height: 24),
                    ],
                    if (published.isNotEmpty) ...[
                      _SectionLabel(label: '📢  Upcoming', color: AppTheme.warning),
                      const SizedBox(height: 10),
                      cardList(published),
                      const SizedBox(height: 24),
                    ],
                    if (closed.isNotEmpty) ...[
                      _SectionLabel(label: '✅  Ended', color: AppTheme.textMuted),
                      const SizedBox(height: 10),
                      cardList(closed),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
    );
  }
}

class _ElectionCard extends ConsumerWidget {
  final ElectionModel election;
  final WidgetRef ref;
  const _ElectionCard({required this.election, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    election.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                _ElectionStatusBadge(status: election.status),
              ],
            ),

            if (election.description != null) ...[
              const SizedBox(height: 6),
              Text(
                election.description!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Status-specific info row
            if (election.isPublished)
              _InfoRow(
                icon: Icons.schedule,
                text: 'Voting opens ${fmt.format(election.startsAt.toLocal())}',
                color: AppTheme.warning,
              ),

            if (election.isActive) ...[
              _VotingProgress(election: election),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.timer_outlined,
                text: 'Voting closes ${fmt.format(election.endsAt.toLocal())}',
                color: AppTheme.success,
              ),
            ],

            if (election.isClosed)
              _InfoRow(
                icon: Icons.lock_outline,
                text: 'Ended ${fmt.format(election.endsAt.toLocal())}',
                color: AppTheme.textMuted,
              ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // CTA row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (election.isActive)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/elections/${election.id}/vote'),
                    icon: const Icon(Icons.how_to_vote, size: 16),
                    label: const Text('Vote Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                if (election.isClosed)
                  OutlinedButton.icon(
                    onPressed: () => context.go('/elections/${election.id}/results'),
                    icon: const Icon(Icons.bar_chart, size: 16),
                    label: const Text('View Results'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (election.isPublished)
                  Text(
                    '${election.positions.length} position${election.positions.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
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
                Text(
                  '${voted.length} of $total positions voted',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (voted.length == total && total > 0)
                  Row(children: const [
                    Icon(Icons.check_circle, size: 13, color: AppTheme.success),
                    SizedBox(width: 4),
                    Text('Complete', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation(AppTheme.success),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _ElectionStatusBadge extends StatelessWidget {
  final String status;
  const _ElectionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppTheme.success; label = '● LIVE'; break;
      case 'published':
        color = AppTheme.warning; label = 'UPCOMING'; break;
      case 'closed':
        color = AppTheme.textMuted; label = 'ENDED'; break;
      default:
        color = AppTheme.textMuted; label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
    );
  }
}
