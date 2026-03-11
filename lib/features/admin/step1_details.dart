// step1_details.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/theme/app_theme.dart';
// import '../../../../../shared/models/models.dart';
// import '../../../../../shared/widgets/shared_widgets.dart';

class Step1Details extends ConsumerStatefulWidget {
  final ElectionModel? election;
  final void Function(String electionId) onCreated;
  final VoidCallback onUpdated;
  final VoidCallback onNext;

  const Step1Details({
    super.key,
    required this.election,
    required this.onCreated,
    required this.onUpdated,
    required this.onNext,
  });

  @override
  ConsumerState<Step1Details> createState() => _Step1DetailsState();
}

class _Step1DetailsState extends ConsumerState<Step1Details> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.election != null) {
      _titleController.text = widget.election!.title;
      _descController.text = widget.election!.description ?? '';
      _startsAt = widget.election!.startsAt;
      _endsAt = widget.election!.endsAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null && mounted) {
      final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
      setState(() { isStart ? _startsAt = dt : _endsAt = dt; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      setState(() { _error = 'Please set start and end dates.'; });
      return;
    }
    if (_endsAt!.isBefore(_startsAt!)) {
      setState(() { _error = 'End date must be after start date.'; });
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final svc = ref.read(supabaseServiceProvider);
      if (widget.election == null) {
        final election = await svc.createElection(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          startsAt: _startsAt!,
          endsAt: _endsAt!,
        );
        widget.onCreated(election.id);
      } else {
        await svc.updateElectionDetails(
          electionId: widget.election!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          startsAt: _startsAt!,
          endsAt: _endsAt!,
        );
        widget.onUpdated();
        widget.onNext();
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    return ResponsiveScaffoldBody(
      maxWidth: Responsive.formMax,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Election Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Basic information about the election.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),

            if (_error != null)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
              ),

            AppTextField(
              label: 'Election Title',
              hint: 'e.g. General Election 2025',
              controller: _titleController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Description (optional)',
              hint: 'Brief description visible to voters',
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            const Text('Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Voting opens and closes automatically at these times.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _DateTile(
                  label: 'Opens',
                  value: _startsAt != null ? fmt.format(_startsAt!) : null,
                  onTap: () => _pickDate(true),
                )),
                const SizedBox(width: 12),
                Expanded(child: _DateTile(
                  label: 'Closes',
                  value: _endsAt != null ? fmt.format(_endsAt!) : null,
                  onTap: () => _pickDate(false),
                )),
              ],
            ),

            const SizedBox(height: 36),
            AppButton(
              label: widget.election == null ? 'Save & Continue' : 'Update & Continue',
              onPressed: _save,
              loading: _saving,
              width: double.infinity,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateTile({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: value != null ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(10),
          color: value != null ? AppTheme.primary.withOpacity(0.04) : AppTheme.cardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_today, size: 12, color: value != null ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 11, color: value != null ? AppTheme.primary : AppTheme.textMuted, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(value ?? 'Set date & time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value != null ? AppTheme.textPrimary : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
