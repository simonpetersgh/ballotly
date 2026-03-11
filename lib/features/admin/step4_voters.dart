// step4_voters.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';
// import 'step2_positions.dart' show _StepNavBar;

class Step4Voters extends ConsumerStatefulWidget {
  final String electionId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step4Voters({
    super.key,
    required this.electionId,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<Step4Voters> createState() => _Step4VotersState();
}

class _Step4VotersState extends ConsumerState<Step4Voters> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addVoter() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || name.isEmpty) {
      setState(() { _error = 'Email and name are required.'; });
      return;
    }
    if (!email.contains('@')) {
      setState(() { _error = 'Enter a valid email address.'; });
      return;
    }

    setState(() { _adding = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).addVoter(
        electionId: widget.electionId,
        email: email,
        fullName: name,
      );
      _emailController.clear();
      _nameController.clear();
      ref.refresh(electionVotersProvider(widget.electionId));
    } catch (e) {
      setState(() {
        _error = e.toString().contains('duplicate')
            ? 'This email is already on the voter list.'
            : 'Failed to add voter. Please try again.';
      });
    } finally {
      if (mounted) setState(() { _adding = false; });
    }
  }

  Future<void> _removeVoter(String voterId) async {
    await ref.read(supabaseServiceProvider).removeVoter(voterId);
    ref.refresh(electionVotersProvider(widget.electionId));
  }

  @override
  Widget build(BuildContext context) {
    final votersAsync = ref.watch(electionVotersProvider(widget.electionId));

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
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eligible Voters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text('Add voters who are eligible to vote in this election.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    votersAsync.when(
                      data: (voters) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${voters.length} added', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Add voter form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Voter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      if (_error != null)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                        ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address', hintText: 'voter@example.com', isDense: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter full name', isDense: true),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _adding ? null : _addVoter,
                          icon: _adding
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.person_add, size: 16),
                          label: Text(_adding ? 'Adding...' : 'Add Voter'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Voters list
                votersAsync.when(
                  loading: () => const LoadingState(),
                  error: (e, _) => ErrorState(message: e.toString()),
                  data: (voters) {
                    if (voters.isEmpty) {
                      return Container(
                        width: double.infinity, padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline, size: 36, color: AppTheme.textMuted),
                            SizedBox(height: 8),
                            Text('No voters added yet.', style: TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: voters.map((voter) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                voter.fullName.isNotEmpty ? voter.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                            ),
                          ),
                          title: Text(voter.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(voter.email, style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                            onPressed: () => _removeVoter(voter.id),
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
            ),
          ),
        ),

        StepNavBar(
          onBack: widget.onBack,
          onNext: widget.onNext, // voters list can be empty — we allow continuing
          nextLabel: 'Continue to Review',
        ),
      ],
    );
  }
}
