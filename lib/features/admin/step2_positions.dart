// step2_positions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';

class Step2Positions extends ConsumerStatefulWidget {
  final String electionId;
  final ElectionModel? election;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onUpdated;

  const Step2Positions({
    super.key,
    required this.electionId,
    required this.election,
    required this.onNext,
    required this.onBack,
    required this.onUpdated,
  });

  @override
  ConsumerState<Step2Positions> createState() => _Step2PositionsState();
}

class _Step2PositionsState extends ConsumerState<Step2Positions> {
  final _newPositionController = TextEditingController();
  bool _adding = false;
  String? _error;

  List<PositionModel> get _positions => widget.election?.positions ?? [];

  Future<void> _addPosition() async {
    final title = _newPositionController.text.trim();
    if (title.isEmpty) return;
    setState(() { _adding = true; _error = null; });
    try {
      await ref.read(supabaseServiceProvider).createPosition(
        electionId: widget.electionId,
        title: title,
        displayOrder: _positions.length,
      );
      _newPositionController.clear();
      widget.onUpdated();
    } catch (e) {
      setState(() { _error = 'Failed to add position.'; });
    } finally {
      if (mounted) setState(() { _adding = false; });
    }
  }

  Future<void> _deletePosition(String positionId) async {
    try {
      await ref.read(supabaseServiceProvider).deletePosition(positionId);
      widget.onUpdated();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Positions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Add the positions voters will choose candidates for.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),

                if (_error != null)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ),

                // Add position input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newPositionController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. President, Secretary...',
                          labelText: 'Position title',
                        ),
                        onFieldSubmitted: (_) => _addPosition(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _adding ? null : _addPosition,
                      child: _adding
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_positions.isEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                    child: const Column(
                      children: [
                        Icon(Icons.ballot_outlined, size: 36, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('No positions yet. Add at least one.', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),

                ..._positions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13))),
                      ),
                      title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.candidates.length} candidate${p.candidates.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                        onPressed: () => _deletePosition(p.id),
                      ),
                    ),
                  );
                }),
              ],
            ),
            ),
          ),
        ),

        // Nav buttons
        StepNavBar(
          onBack: widget.onBack,
          onNext: _positions.isNotEmpty ? widget.onNext : null,
          nextLabel: 'Continue to Candidates',
        ),
      ],
    );
  }
}

