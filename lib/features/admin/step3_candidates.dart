// lib/features/admin/presentation/screens/election_setup/step3_candidates.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';

class Step3Candidates extends ConsumerStatefulWidget {
  final String electionId;
  final ElectionModel? election;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onUpdated;

  const Step3Candidates({
    super.key,
    required this.electionId,
    required this.election,
    required this.onNext,
    required this.onBack,
    required this.onUpdated,
  });

  @override
  ConsumerState<Step3Candidates> createState() => _Step3CandidatesState();
}

class _Step3CandidatesState extends ConsumerState<Step3Candidates> {
  String? _expandedPositionId;

  List<PositionModel> get _positions => widget.election?.positions ?? [];

  bool get _allPositionsHaveCandidates =>
      _positions.isNotEmpty &&
      _positions.every((p) => p.candidates.length >= 2);

  @override
  void initState() {
    super.initState();
    if (_positions.isNotEmpty) _expandedPositionId = _positions.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ResponsiveScaffoldBody(
            maxWidth: Responsive.formMax,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Candidates',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text(
                    'Add at least 2 candidates per position. '
                    'Ballot numbers are optional — they determine the order candidates appear on the voting page.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  ..._positions.map((p) => _PositionCandidateSection(
                        position: p,
                        isExpanded: _expandedPositionId == p.id,
                        onToggle: () => setState(() {
                          _expandedPositionId =
                              _expandedPositionId == p.id ? null : p.id;
                        }),
                        onUpdated: widget.onUpdated,
                        ref: ref,
                      )),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        StepNavBar(
          onBack: widget.onBack,
          onNext: _allPositionsHaveCandidates ? widget.onNext : null,
          nextLabel: 'Continue to Voters',
        ),
      ],
    );
  }
}

// ─── POSITION SECTION ─────────────────────────────────────────────────────────

class _PositionCandidateSection extends StatefulWidget {
  final PositionModel position;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onUpdated;
  final WidgetRef ref;

  const _PositionCandidateSection({
    required this.position,
    required this.isExpanded,
    required this.onToggle,
    required this.onUpdated,
    required this.ref,
  });

  @override
  State<_PositionCandidateSection> createState() =>
      _PositionCandidateSectionState();
}

class _PositionCandidateSectionState
    extends State<_PositionCandidateSection> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _ballotCtrl = TextEditingController();
  bool _adding = false;

  // Editing state
  String? _editingId;
  final _editNameCtrl = TextEditingController();
  final _editBioCtrl = TextEditingController();
  final _editPhotoCtrl = TextEditingController();
  final _editBallotCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _photoCtrl.dispose();
    _ballotCtrl.dispose();
    _editNameCtrl.dispose();
    _editBioCtrl.dispose();
    _editPhotoCtrl.dispose();
    _editBallotCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCandidate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    try {
      await widget.ref.read(supabaseServiceProvider).createCandidate(
            positionId: widget.position.id,
            name: name,
            bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
            photoUrl: _photoCtrl.text.trim().isEmpty
                ? null
                : _photoCtrl.text.trim(),
            ballotNumber: int.tryParse(_ballotCtrl.text.trim()),
          );
      _nameCtrl.clear();
      _bioCtrl.clear();
      _photoCtrl.clear();
      _ballotCtrl.clear();
      widget.onUpdated();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _startEdit(CandidateModel c) {
    setState(() {
      _editingId = c.id;
      _editNameCtrl.text = c.name;
      _editBioCtrl.text = c.bio ?? '';
      _editPhotoCtrl.text = c.photoUrl ?? '';
      _editBallotCtrl.text = c.ballotNumber?.toString() ?? '';
    });
  }

  Future<void> _saveEdit(String candidateId) async {
    final name = _editNameCtrl.text.trim();
    if (name.isEmpty) return;
    await widget.ref.read(supabaseServiceProvider).updateCandidate(
          candidateId: candidateId,
          name: name,
          bio: _editBioCtrl.text.trim().isEmpty
              ? null
              : _editBioCtrl.text.trim(),
          photoUrl: _editPhotoCtrl.text.trim().isEmpty
              ? null
              : _editPhotoCtrl.text.trim(),
          ballotNumber: int.tryParse(_editBallotCtrl.text.trim()),
        );
    setState(() => _editingId = null);
    widget.onUpdated();
  }

  Future<void> _deleteCandidate(String candidateId) async {
    await widget.ref.read(supabaseServiceProvider).deleteCandidate(candidateId);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final hasEnough = widget.position.candidates.length >= 2;
    final sorted = widget.position.sortedCandidates;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: widget.onToggle,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasEnough
                          ? AppTheme.success.withOpacity(0.1)
                          : AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasEnough
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color: hasEnough ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.position.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        Text(
                          '${widget.position.candidates.length} candidate${widget.position.candidates.length == 1 ? '' : 's'}'
                          '${hasEnough ? '' : ' — add at least 2'}',
                          style: TextStyle(
                              fontSize: 12,
                              color: hasEnough
                                  ? AppTheme.textMuted
                                  : AppTheme.warning),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          if (widget.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Existing candidates
                  ...sorted.map((c) => _editingId == c.id
                      ? _EditRow(
                          candidate: c,
                          nameCtrl: _editNameCtrl,
                          bioCtrl: _editBioCtrl,
                          photoCtrl: _editPhotoCtrl,
                          ballotCtrl: _editBallotCtrl,
                          onSave: () => _saveEdit(c.id),
                          onCancel: () =>
                              setState(() => _editingId = null),
                        )
                      : _CandidateRow(
                          candidate: c,
                          onEdit: () => _startEdit(c),
                          onDelete: () => _deleteCandidate(c.id),
                        )),

                  const SizedBox(height: 8),

                  // Add candidate form
                  _AddCandidateForm(
                    nameCtrl: _nameCtrl,
                    bioCtrl: _bioCtrl,
                    photoCtrl: _photoCtrl,
                    ballotCtrl: _ballotCtrl,
                    adding: _adding,
                    onAdd: _addCandidate,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── CANDIDATE ROW (display) ──────────────────────────────────────────────────

class _CandidateRow extends StatelessWidget {
  final CandidateModel candidate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CandidateRow({
    required this.candidate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CandidateAvatar(
            name: candidate.name,
            photoUrl: candidate.photoUrl,
            ballotNumber: candidate.ballotNumber,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (candidate.ballotNumber != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${candidate.ballotNumber}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(candidate.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                if (candidate.bio != null && candidate.bio!.isNotEmpty)
                  Text(candidate.bio!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: AppTheme.textSecondary),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                size: 16, color: AppTheme.danger),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── EDIT ROW ────────────────────────────────────────────────────────────────

class _EditRow extends StatelessWidget {
  final CandidateModel candidate;
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController photoCtrl;
  final TextEditingController ballotCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditRow({
    required this.candidate,
    required this.nameCtrl,
    required this.bioCtrl,
    required this.photoCtrl,
    required this.ballotCtrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Name', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ballotCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ballot #', isDense: true),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: bioCtrl,
            decoration:
                const InputDecoration(labelText: 'Bio', isDense: true),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: photoCtrl,
            decoration: const InputDecoration(
                labelText: 'Photo URL', isDense: true),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: onSave,
                  child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ADD CANDIDATE FORM ───────────────────────────────────────────────────────

class _AddCandidateForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController photoCtrl;
  final TextEditingController ballotCtrl;
  final bool adding;
  final VoidCallback onAdd;

  const _AddCandidateForm({
    required this.nameCtrl,
    required this.bioCtrl,
    required this.photoCtrl,
    required this.ballotCtrl,
    required this.adding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add candidate',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full name *', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ballotCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ballot #', isDense: true),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: bioCtrl,
            decoration: const InputDecoration(
                labelText: 'Short bio (optional)', isDense: true),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: photoCtrl,
            decoration: const InputDecoration(
              labelText: 'Photo URL (optional)',
              hintText: 'https://...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: adding ? null : onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(adding ? 'Adding...' : 'Add Candidate'),
            ),
          ),
        ],
      ),
    );
  }
}
