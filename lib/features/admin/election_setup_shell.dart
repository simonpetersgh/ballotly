// lib/features/admin/presentation/screens/election_setup/election_setup_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';
import 'step1_details.dart';
import 'step2_positions.dart';
import 'step3_candidates.dart';
import 'step4_voters.dart';
import 'step5_review.dart';

class ElectionSetupShell extends ConsumerStatefulWidget {
  final String? electionId;
  final int initialStep;

  const ElectionSetupShell({
    super.key,
    required this.electionId,
    this.initialStep = 0,
  });

  @override
  ConsumerState<ElectionSetupShell> createState() => _ElectionSetupShellState();
}

class _ElectionSetupShellState extends ConsumerState<ElectionSetupShell> {
  late int _currentStep;
  String? _electionId;
  ElectionModel? _election;
  bool _loading = true;

  final List<String> _stepTitles = [
    'Details',
    'Positions',
    'Candidates',
    'Voters',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _electionId = widget.electionId;
    _loadElection();
  }

  Future<void> _loadElection() async {
    if (_electionId == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final election = await ref.read(supabaseServiceProvider).getElection(_electionId!);
      setState(() { _election = election; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  void _onElectionCreated(String electionId) {
    setState(() {
      _electionId = electionId;
      _loading = true;
    });
    _loadElection();
    _nextStep();
  }

  void _onElectionUpdated() {
    _loadElection();
  }

  void _nextStep() {
    if (_currentStep < 4) setState(() { _currentStep++; });
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() { _currentStep--; });
  }

  void _goToStep(int step) {
    // Can only go back or to already-unlocked steps
    if (step <= _currentStep && _electionId != null) {
      setState(() { _currentStep = step; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Step indicator
          Container(
            color: AppTheme.cardBg,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/admin'),
                      child: const Icon(Icons.close, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _election?.title ?? 'New Election',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_election != null)
                      StatusChip(status: _election!.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Step pills
                Row(
                  children: List.generate(_stepTitles.length, (i) {
                    final isActive = i == _currentStep;
                    final isCompleted = i < _currentStep && _electionId != null;
                    final isAccessible = i <= _currentStep && _electionId != null || i == 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: isAccessible ? () => _goToStep(i) : null,
                        child: Padding(
                          padding: EdgeInsets.only(right: i < _stepTitles.length - 1 ? 6 : 0),
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.primary
                                      : isCompleted
                                          ? AppTheme.success
                                          : AppTheme.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _stepTitles[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                  color: isActive
                                      ? AppTheme.primary
                                      : isCompleted
                                          ? AppTheme.success
                                          : AppTheme.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Step content
          Expanded(
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return Step1Details(
          election: _election,
          onCreated: _onElectionCreated,
          onUpdated: _onElectionUpdated,
          onNext: _nextStep,
        );
      case 1:
        return Step2Positions(
          electionId: _electionId!,
          election: _election,
          onNext: _nextStep,
          onBack: _prevStep,
          onUpdated: _onElectionUpdated,
        );
      case 2:
        return Step3Candidates(
          electionId: _electionId!,
          election: _election,
          onNext: _nextStep,
          onBack: _prevStep,
          onUpdated: _onElectionUpdated,
        );
      case 3:
        return Step4Voters(
          electionId: _electionId!,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 4:
        return Step5Review(
          electionId: _electionId!,
          election: _election,
          onBack: _prevStep,
          onPublished: () => context.go('/admin'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
