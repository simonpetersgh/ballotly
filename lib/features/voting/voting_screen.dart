// lib/features/voting/presentation/screens/voting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/models.dart';
// import '../../../../shared/widgets/shared_widgets.dart';

class VotingScreen extends ConsumerStatefulWidget {
  final String electionId;
  const VotingScreen({super.key, required this.electionId});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  int _currentIndex = 0;
  String? _selectedCandidateId;
  bool _confirmed = false;
  bool _submitting = false;
  String? _error;

  List<PositionModel> _unvoted(
          List<PositionModel> positions, List<String> voted) =>
      positions.where((p) => !voted.contains(p.id)).toList();

  Future<void> _castVote(VoterModel voter, PositionModel position) async {
    if (_selectedCandidateId == null) {
      setState(() => _error = 'Please select a candidate.');
      return;
    }
    if (!_confirmed) {
      setState(() => _error = 'Please confirm your selection.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(supabaseServiceProvider).castVote(
            voterId: voter.id,
            positionId: position.id,
            candidateId: _selectedCandidateId!,
          );
      ref.invalidate(votedPositionsProvider(widget.electionId));
      setState(() {
        _currentIndex++;
        _selectedCandidateId = null;
        _confirmed = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('duplicate')
            ? 'You have already voted for this position.'
            : 'Failed to submit vote. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final electionAsync = ref.watch(electionProvider(widget.electionId));
    final voterAsync = ref.watch(myVoterRecordProvider(widget.electionId));
    final votedAsync = ref.watch(votedPositionsProvider(widget.electionId));

    return electionAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (election) {
        // Guard: only active elections
        if (!election.isActive) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      election.isPublished
                          ? 'Voting has not started yet.'
                          : 'This election has ended.',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Back to Elections',
                      outlined: true,
                      onPressed: () => context.go('/elections'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Guard: eligible voter
        return voterAsync.when(
          loading: () => const Scaffold(body: LoadingState()),
          error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
          data: (voter) {
            if (voter == null) {
              return Scaffold(
                body: EmptyState(
                  icon: Icons.block,
                  title: 'Not eligible',
                  subtitle:
                      'You are not on the voter list for this election.',
                  action: AppButton(
                    label: 'Back to Elections',
                    outlined: true,
                    onPressed: () => context.go('/elections'),
                  ),
                ),
              );
            }

            return votedAsync.when(
              loading: () => const Scaffold(body: LoadingState()),
              error: (e, _) =>
                  Scaffold(body: ErrorState(message: e.toString())),
              data: (votedPositions) {
                final unvoted =
                    _unvoted(election.positions, votedPositions);

                if (unvoted.isEmpty || _currentIndex >= unvoted.length) {
                  return _CompletionScreen(
                    electionId: widget.electionId,
                    electionTitle: election.title,
                  );
                }

                final position = unvoted[_currentIndex];
                final candidates = position.sortedCandidates;
                final progress = _currentIndex / unvoted.length;
                final isDesktop = Responsive.isDesktop(context);

                return Scaffold(
                  backgroundColor: AppTheme.surface,
                  body: Column(
                    children: [
                      // Progress header
                      Container(
                        color: AppTheme.cardBg,
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 40 : 20, 16, isDesktop ? 40 : 20, 16),
                        child: ResponsiveScaffoldBody(
                          maxWidth: Responsive.contentMax,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        context.go('/elections'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(election.title,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary),
                                            overflow:
                                                TextOverflow.ellipsis),
                                        Text(
                                          'Position ${_currentIndex + 1} of ${unvoted.length}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.border,
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Ballot
                      Expanded(
                        child: SingleChildScrollView(
                          child: ResponsiveScaffoldBody(
                            maxWidth: Responsive.contentMax,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    isDesktop ? 40 : 20,
                                vertical: 24,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(position.title,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(height: 4),
                                  const Text('Select one candidate',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14)),
                                  const SizedBox(height: 20),

                                  if (_error != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      margin: const EdgeInsets.only(
                                          bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppTheme.danger
                                                .withOpacity(0.3)),
                                      ),
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: AppTheme.danger,
                                              fontSize: 14)),
                                    ),

                                  // Candidate cards — 2-col grid on desktop
                                  isDesktop
                                      ? _CandidateGrid(
                                          candidates: candidates,
                                          selectedId:
                                              _selectedCandidateId,
                                          onSelect: (id) => setState(() {
                                            _selectedCandidateId = id;
                                            _confirmed = false;
                                            _error = null;
                                          }),
                                        )
                                      : Column(
                                          children: candidates
                                              .map((c) => _CandidateCard(
                                                    candidate: c,
                                                    isSelected:
                                                        _selectedCandidateId ==
                                                            c.id,
                                                    onTap: () =>
                                                        setState(() {
                                                      _selectedCandidateId =
                                                          c.id;
                                                      _confirmed = false;
                                                      _error = null;
                                                    }),
                                                  ))
                                              .toList(),
                                        ),

                                  const SizedBox(height: 20),

                                  // Confirm checkbox
                                  if (_selectedCandidateId != null)
                                    InkWell(
                                      onTap: () => setState(
                                          () => _confirmed = !_confirmed),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: _confirmed
                                              ? AppTheme.primary
                                                  .withOpacity(0.06)
                                              : AppTheme.cardBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: _confirmed
                                                  ? AppTheme.primary
                                                  : AppTheme.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _confirmed
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              color: _confirmed
                                                  ? AppTheme.primary
                                                  : AppTheme.textMuted,
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'I confirm this is my final selection for this position.',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme
                                                        .textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 24),
                                  AppButton(
                                    label: 'Submit Vote',
                                    icon: Icons.how_to_vote,
                                    onPressed: _confirmed
                                        ? () => _castVote(voter, position)
                                        : null,
                                    loading: _submitting,
                                    width: double.infinity,
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── CANDIDATE GRID (desktop 2-col) ───────────────────────────────────────────

class _CandidateGrid extends StatelessWidget {
  final List<CandidateModel> candidates;
  final String? selectedId;
  final void Function(String) onSelect;

  const _CandidateGrid({
    required this.candidates,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // pair candidates into rows of 2
    final rows = <List<CandidateModel>>[];
    for (var i = 0; i < candidates.length; i += 2) {
      rows.add(candidates.sublist(i,
          i + 2 > candidates.length ? candidates.length : i + 2));
    }
    return Column(
      children: rows.map((row) {
        return Row(
          children: [
            Expanded(
              child: _CandidateCard(
                candidate: row[0],
                isSelected: selectedId == row[0].id,
                onTap: () => onSelect(row[0].id),
              ),
            ),
            if (row.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _CandidateCard(
                  candidate: row[1],
                  isSelected: selectedId == row[1].id,
                  onTap: () => onSelect(row[1].id),
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

// ─── CANDIDATE CARD ───────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final bool isSelected;
  final VoidCallback onTap;

  const _CandidateCard({
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.06)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CandidateAvatar(
              name: candidate.name,
              photoUrl: candidate.photoUrl,
              ballotNumber: candidate.ballotNumber,
              size: 52,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (candidate.bio != null && candidate.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        candidate.bio!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPLETION SCREEN ────────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  final String electionId;
  final String electionTitle;
  const _CompletionScreen(
      {required this.electionId, required this.electionTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Responsive.contentMax),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 48, color: AppTheme.success),
                ),
                const SizedBox(height: 24),
                const Text('All Votes Submitted!',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'You have successfully cast all your votes in $electionTitle.',
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                AppButton(
                  label: 'View Results',
                  icon: Icons.bar_chart,
                  onPressed: () =>
                      context.go('/elections/$electionId/results'),
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Back to Elections',
                  outlined: true,
                  onPressed: () => context.go('/elections'),
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
