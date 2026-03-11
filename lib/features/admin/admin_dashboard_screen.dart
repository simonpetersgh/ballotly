// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionsAsync = ref.watch(allElectionsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.when(
                    data: (p) => Text(
                      'Hello, ${p?.fullName.split(' ').first ?? 'Organiser'} 👋',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    loading: () => const SizedBox(height: 28),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage your elections below.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: electionsAsync.when(
                data: (elections) => LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 480;
                    final tiles = [
                      _StatTile(label: 'Total', value: '${elections.length}', color: AppTheme.primary),
                      _StatTile(label: 'Active', value: '${elections.where((e) => e.isActive).length}', color: AppTheme.success),
                      _StatTile(label: 'Draft', value: '${elections.where((e) => e.isDraft).length}', color: AppTheme.warning),
                      _StatTile(label: 'Closed', value: '${elections.where((e) => e.isClosed).length}', color: AppTheme.textMuted),
                    ];
                    if (isMobile) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: tiles,
                      );
                    }
                    return Row(
                      children: tiles
                          .expand((t) => [t, const SizedBox(width: 10)])
                          .toList()
                        ..removeLast(),
                    );
                  },
                ),
                loading: () => const SizedBox(height: 60),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // New election button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AppButton(
                label: 'New Election',
                icon: Icons.add,
                onPressed: () => context.go('/admin/elections/new'),
                width: double.infinity,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Text('Elections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const Spacer(),
                  TextButton(onPressed: () => ref.refresh(allElectionsProvider), child: const Text('Refresh')),
                ],
              ),
            ),
          ),

          electionsAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingState()),
            error: (e, _) => SliverFillRemaining(child: ErrorState(message: e.toString(), onRetry: () => ref.refresh(allElectionsProvider))),
            data: (elections) {
              if (elections.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.ballot_outlined,
                    title: 'No elections yet',
                    subtitle: 'Create your first election to get started.',
                    action: AppButton(label: 'New Election', icon: Icons.add, onPressed: () => context.go('/admin/elections/new')),
                  ),
                );
              }

              // Group by status order: active, published, draft, closed
              final ordered = [
                ...elections.where((e) => e.isActive),
                ...elections.where((e) => e.isPublished),
                ...elections.where((e) => e.isDraft),
                ...elections.where((e) => e.isClosed),
              ];

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AdminElectionCard(election: ordered[i], ref: ref),
                    childCount: ordered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _AdminElectionCard extends StatelessWidget {
  final ElectionModel election;
  final WidgetRef ref;
  const _AdminElectionCard({required this.election, required this.ref});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    final labels = {
      'active': 'Go Live',
      'closed': 'Close Election',
      'draft': 'Move to Draft',
      'published': 'Publish',
    };
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${labels[newStatus] ?? newStatus}?'),
        content: Text(newStatus == 'closed'
            ? 'This will permanently close the election. Voters will no longer be able to vote.'
            : 'Are you sure you want to change the election status?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: newStatus == 'closed' ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger) : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(supabaseServiceProvider).updateElectionStatus(election.id, newStatus);
      ref.refresh(allElectionsProvider);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Election?'),
        content: const Text('This will permanently delete the election and all its data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(supabaseServiceProvider).deleteElection(election.id);
      ref.refresh(allElectionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(election.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                StatusChip(status: election.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${election.positions.length} positions  ·  ${fmt.format(election.startsAt)} – ${fmt.format(election.endsAt)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                // Draft actions
                if (election.isDraft) ...[
                  _Btn(label: 'Continue Setup', icon: Icons.edit, onPressed: () => context.go('/admin/elections/${election.id}/setup')),
                  _Btn(label: 'Publish', icon: Icons.publish, color: AppTheme.primary, onPressed: () => _updateStatus(context, ref, SupabaseConstants.statusPublished)),
                  _Btn(label: 'Delete', icon: Icons.delete_outline, color: AppTheme.danger, onPressed: () => _delete(context, ref)),
                ],
                // Published actions
                if (election.isPublished) ...[
                  _Btn(label: 'Edit', icon: Icons.edit, onPressed: () => context.go('/admin/elections/${election.id}/setup')),
                  _Btn(label: 'Go Live Now', icon: Icons.play_arrow, color: AppTheme.success, onPressed: () => _updateStatus(context, ref, SupabaseConstants.statusActive)),
                  _Btn(label: 'Voters', icon: Icons.people, onPressed: () => context.go('/admin/elections/${election.id}/voters')),
                  _Btn(label: 'Back to Draft', icon: Icons.undo, onPressed: () => _updateStatus(context, ref, SupabaseConstants.statusDraft)),
                ],
                // Active actions
                if (election.isActive) ...[
                  _Btn(label: 'Results', icon: Icons.bar_chart, onPressed: () => context.go('/admin/elections/${election.id}/results')),
                  _Btn(label: 'Voters', icon: Icons.people, onPressed: () => context.go('/admin/elections/${election.id}/voters')),
                  _Btn(label: 'Close Now', icon: Icons.lock, color: AppTheme.danger, onPressed: () => _updateStatus(context, ref, SupabaseConstants.statusClosed)),
                ],
                // Closed actions
                if (election.isClosed)
                  _Btn(label: 'View Results', icon: Icons.bar_chart, onPressed: () => context.go('/admin/elections/${election.id}/results')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _Btn({required this.label, required this.icon, required this.onPressed, this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
