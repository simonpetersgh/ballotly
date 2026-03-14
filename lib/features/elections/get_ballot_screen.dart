
// lib/features/guest/presentation/screens/guest_ballot_screen.dart
//
// Receives {voterId, email} via GoRouter extra from GuestEntryScreen.
// Shares the same ballot UI as VotingScreen but is auth-agnostic:
// it works for both registered voters and guests who just verified via OTP.
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';

class GuestBallotScreen extends ConsumerStatefulWidget {
  final String electionId;
  final String voterId;
  final String voterEmail;

  const GuestBallotScreen({
    super.key,
    required this.electionId,
    required this.voterId,
    required this.voterEmail,
  });

  @override
  ConsumerState<GuestBallotScreen> createState() => _GuestBallotScreenState();
}

class _GuestBallotScreenState extends ConsumerState<GuestBallotScreen> {
  int _currentIndex = 0;
  String? _selectedCandidateId;
  bool _confirmed = false;
  bool _submitting = false;
  String? _error;

  // Voted position IDs cached locally so we don't re-fetch after each vote
  late Future<List<String>> _votedFuture;

  @override
  void initState() {
    super.initState();
    _votedFuture = ref
        .read(supabaseServiceProvider)
        .getVotedPositionsByVoterId(widget.voterId);
  }

  List<PositionModel> _unvoted(
          List<PositionModel> positions, List<String> voted) =>
      positions.where((p) => !voted.contains(p.id)).toList();

  Future<void> _castVote(
      List<PositionModel> unvoted, List<String> alreadyVoted) async {
    if (_selectedCandidateId == null) {
      setState(() => _error = 'Please select a candidate.');
      return;
    }
    if (!_confirmed) {
      setState(() => _error = 'Please confirm your selection.');
      return;
    }

    final position = unvoted[_currentIndex];

    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).castVote(
            voterId: widget.voterId,
            positionId: position.id,
            candidateId: _selectedCandidateId!,
          );

      // Refresh local voted list
      final fresh = await ref
          .read(supabaseServiceProvider)
          .getVotedPositionsByVoterId(widget.voterId);

      setState(() {
        _votedFuture = Future.value(fresh);
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

    return electionAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (election) {
        // Guard: must be active to vote
        if (!election.isActive) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      election.isClosed
                          ? Icons.lock_outline
                          : Icons.schedule_rounded,
                      size: 60,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      election.isClosed
                          ? 'Voting has ended'
                          : 'Voting has not started yet',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      election.isClosed
                          ? 'This election is closed. You can view the results.'
                          : 'Voting opens ${_formatDate(election.startsAt)}.',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (election.isClosed)
                      AppButton(
                        label: 'View Results',
                        icon: Icons.bar_chart_rounded,
                        onPressed: () => context.go(
                            '/results/${widget.electionId}'),
                        width: double.infinity,
                      ),
                    const SizedBox(height: 12),
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

        return FutureBuilder<List<String>>(
          future: _votedFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: LoadingState());
            }
            if (snap.hasError) {
              return Scaffold(
                  body: ErrorState(message: snap.error.toString()));
            }

            final votedPositions = snap.data ?? [];
            final unvoted = _unvoted(election.positions, votedPositions);

            // All positions voted
            if (unvoted.isEmpty || _currentIndex >= unvoted.length) {
              return _GuestCompletionScreen(
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
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => _showExitDialog(context),
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
                                        overflow: TextOverflow.ellipsis),
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
                              // Guest badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Guest',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accent)),
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
                              valueColor: const AlwaysStoppedAnimation(
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
                            horizontal: isDesktop ? 40 : 20,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.danger.withOpacity(0.08),
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

                              // Candidate cards
                              isDesktop
                                  ? _CandidateGrid(
                                      candidates: candidates,
                                      selectedId: _selectedCandidateId,
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
                                                onTap: () => setState(() {
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
                                  borderRadius: BorderRadius.circular(10),
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
                                                color:
                                                    AppTheme.textPrimary),
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
                                    ? () => _castVote(unvoted, votedPositions)
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
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave ballot?'),
        content: const Text(
            'Votes already submitted will be saved. You can return to complete remaining positions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Leave',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} at $hour:$min $ampm';
  }
}

// ─── COMPLETION ───────────────────────────────────────────────────────────────

class _GuestCompletionScreen extends StatelessWidget {
  final String electionId;
  final String electionTitle;
  const _GuestCompletionScreen(
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
                  width: 80, height: 80,
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
                  icon: Icons.bar_chart_rounded,
                  onPressed: () =>
                      context.go('/results/$electionId'),
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
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
      ),
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
    final rows = <List<CandidateModel>>[];
    for (var i = 0; i < candidates.length; i += 2) {
      rows.add(candidates.sublist(
          i, i + 2 > candidates.length ? candidates.length : i + 2));
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
                  Text(candidate.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  if (candidate.bio != null && candidate.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(candidate.bio!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primary : AppTheme.textMuted,
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
