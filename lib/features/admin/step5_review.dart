// step5_review.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/constants/supabase_constants.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';

class Step5Review extends ConsumerStatefulWidget {
  final String electionId;
  final ElectionModel? election;
  final VoidCallback onBack;
  final VoidCallback onPublished;

  const Step5Review({
    super.key,
    required this.electionId,
    required this.election,
    required this.onBack,
    required this.onPublished,
  });

  @override
  ConsumerState<Step5Review> createState() => _Step5ReviewState();
}

class _Step5ReviewState extends ConsumerState<Step5Review> {
  bool _publishing = false;
  String? _error;

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .updateElectionStatus(
            widget.electionId,
            SupabaseConstants.statusPublished,
          );
      ref.refresh(allElectionsProvider);
      widget.onPublished();
    } catch (e) {
      setState(() {
        _error = 'Failed to publish. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _publishing = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final election = widget.election;
    final votersAsync = ref.watch(electionVotersProvider(widget.electionId));
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    if (election == null) return const LoadingState();

    final positions = election.positions;
    final totalCandidates = positions.fold<int>(
      0,
      (sum, p) => sum + p.candidates.length,
    );
    final allReady =
        positions.isNotEmpty &&
        positions.every((p) => p.candidates.length >= 2);

    return Column(
      children: [
        Expanded(
          child: ResponsiveScaffoldBody(
            maxWidth: Responsive.formMax,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review & Publish',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review your election setup before publishing it to voters.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),

                  // Election summary card
                  _ReviewCard(
                    title: 'Election Details',
                    icon: Icons.info_outline,
                    children: [
                      _ReviewRow(label: 'Title', value: election.title),
                      if (election.description != null)
                        _ReviewRow(
                          label: 'Description',
                          value: election.description!,
                        ),
                      _ReviewRow(
                        label: 'Opens',
                        value: fmt.format(election.startsAt.toLocal()),
                      ),
                      _ReviewRow(
                        label: 'Closes',
                        value: fmt.format(election.endsAt.toLocal()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Positions summary
                  _ReviewCard(
                    title: 'Positions & Candidates',
                    icon: Icons.ballot_outlined,
                    trailing: Text(
                      '$totalCandidates total candidates',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    children: positions
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  p.candidates.length >= 2
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_outlined,
                                  size: 16,
                                  color: p.candidates.length >= 2
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${p.candidates.length} candidates',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 14),

                  // Voters summary
                  _ReviewCard(
                    title: 'Eligible Voters',
                    icon: Icons.people_outline,
                    children: [
                      votersAsync.when(
                        data: (voters) => _ReviewRow(
                          label: 'Total voters',
                          value: '${voters.length}',
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Could not load voter count'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Readiness check
                  if (!allReady)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Some positions have fewer than 2 candidates. Go back to fix before publishing.',
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // Nav
        Container(
          color: AppTheme.cardBg,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              if (allReady)
                AppButton(
                  label: 'Publish Election',
                  icon: Icons.publish,
                  onPressed: _publishing ? null : _publish,
                  loading: _publishing,
                  width: double.infinity,
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
