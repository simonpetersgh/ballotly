// step1_details.dart
//
// Step 1 covers two sections:
//   A) Basic details (title, description, schedule)  — saved via createElection / updateElectionDetails
//   B) Verification settings (mode, secondary token)  — saved via updateElectionVerification
//
// PREMIUM FEATURES in this step (guards commented out):
//   • OTP verification mode
//   • Secondary token
//
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
  final _formKey        = GlobalKey<FormState>();
  final _titleCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;

  // ── Verification settings ────────────────────────────────────────────────
  String _verificationMode     = SupabaseConstants.verificationManual;
  bool   _secondaryTokenEnabled = false;

  bool    _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.election;
    if (e != null) {
      _titleCtrl.text          = e.title;
      _descCtrl.text           = e.description ?? '';
      _startsAt                = e.startsAt;
      _endsAt                  = e.endsAt;
      _verificationMode        = e.verificationMode;
      _secondaryTokenEnabled   = e.secondaryTokenEnabled;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (time != null && mounted) {
      final dt = DateTime(
          picked.year, picked.month, picked.day, time.hour, time.minute);
      setState(() => isStart ? _startsAt = dt : _endsAt = dt);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      setState(() => _error = 'Please set start and end dates.');
      return;
    }
    if (_endsAt!.isBefore(_startsAt!)) {
      setState(() => _error = 'End date must be after start date.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final svc = ref.read(supabaseServiceProvider);

      String electionId;

      if (widget.election == null) {
        // Create election (basic details only — verification saved after)
        final election = await svc.createElection(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          startsAt: _startsAt!,
          endsAt: _endsAt!,
        );
        electionId = election.id;
      } else {
        electionId = widget.election!.id;
        await svc.updateElectionDetails(
          electionId: electionId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          startsAt: _startsAt!,
          endsAt: _endsAt!,
        );
      }

      // Save verification settings (always — even on create)
      await svc.updateElectionVerification(
        electionId: electionId,
        verificationMode: _verificationMode,
        secondaryTokenEnabled: _secondaryTokenEnabled,
      );

      if (widget.election == null) {
        widget.onCreated(electionId);
      } else {
        widget.onUpdated();
        widget.onNext();
      }
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
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

              // ── Section A: Details ───────────────────────────────────────
              const Text('Election Details',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Basic information about the election.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 28),

              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style:
                          const TextStyle(color: AppTheme.danger)),
                ),

              AppTextField(
                label: 'Election Title',
                hint: 'e.g. General Election 2025',
                controller: _titleCtrl,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (optional)',
                hint: 'Brief description visible to voters',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              const Text('Schedule',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text(
                  'Voting opens and closes automatically at these times.',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: _DateTile(
                    label: 'Opens',
                    value: _startsAt != null
                        ? fmt.format(_startsAt!)
                        : null,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'Closes',
                    value: _endsAt != null
                        ? fmt.format(_endsAt!)
                        : null,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),

              // ── Section B: Verification Settings ────────────────────────
              const SizedBox(height: 36),
              _SectionDivider(
                title: 'Verification Settings',
                subtitle:
                    'How voters prove their identity when accessing the ballot.',
              ),
              const SizedBox(height: 20),

              // ── Verification mode ────────────────────────────────────────
              const Text('Verification Method',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),

              // Token (manual) — FREE
              _VerificationOption(
                selected:
                    _verificationMode == SupabaseConstants.verificationManual,
                icon: Icons.key_rounded,
                title: 'Token Verification',
                subtitle:
                    'Voters enter a primary (and optional secondary) '
                    'token set by you. Simple and works without email.',
                badge: null, // Free tier
                onTap: () => setState(() =>
                    _verificationMode = SupabaseConstants.verificationManual),
              ),

              const SizedBox(height: 10),

              // OTP — PREMIUM (guard commented out below)
              _VerificationOption(
                selected:
                    _verificationMode == SupabaseConstants.verificationOtp,
                icon: Icons.mark_email_read_outlined,
                title: 'OTP Verification',
                subtitle:
                    'Voters receive a one-time code by email to access '
                    'the ballot. Higher assurance, no tokens to manage.',
                badge: _PremiumBadge(),
                onTap: () {
                  // ── PREMIUM GATE (uncomment when payment ready) ────────
                  // if (!election.isPaid) {
                  //   _showUpgradeDialog(context, 'OTP verification is a premium feature.');
                  //   return;
                  // }
                  setState(() =>
                      _verificationMode = SupabaseConstants.verificationOtp);
                },
              ),

              // ── Secondary token ──────────────────────────────────────────
              const SizedBox(height: 20),
              _ToggleSetting(
                icon: Icons.vpn_key_outlined,
                title: 'Secondary Token',
                subtitle:
                    'Require voters to enter a second token for extra '
                    'verification. Only applies to Token Verification.',
                badge: _PremiumBadge(),
                value: _secondaryTokenEnabled,
                onChanged: (v) {
                  // ── PREMIUM GATE (uncomment when payment ready) ────────
                  // if (v && !election.isPaid) {
                  //   _showUpgradeDialog(context, 'Secondary token is a premium feature.');
                  //   return;
                  // }
                  setState(() => _secondaryTokenEnabled = v);
                },
                // Disable toggle if mode is OTP (tokens don't apply)
                enabled: _verificationMode == SupabaseConstants.verificationManual,
                disabledReason: 'Secondary token is not used in OTP mode.',
              ),

              const SizedBox(height: 36),
              AppButton(
                label: widget.election == null
                    ? 'Save & Continue'
                    : 'Update & Continue',
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

// ── Uncomment this method when adding payment integration ──────────────────
// void _showUpgradeDialog(BuildContext context, String reason) {
//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: const Text('Premium Feature'),
//       content: Text('$reason Upgrade this election to unlock it.'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Maybe Later'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context);
//             // TODO: navigate to payment / upgrade flow
//           },
//           child: const Text('Upgrade'),
//         ),
//       ],
//     ),
//   );
// }
}

// ─── SECTION DIVIDER ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionDivider({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
      ],
    );
  }
}

// ─── VERIFICATION OPTION CARD ─────────────────────────────────────────────────

class _VerificationOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  const _VerificationOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.06)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withOpacity(0.12)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected ? AppTheme.primary : AppTheme.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary)),
                    if (badge != null) ...[
                      const SizedBox(width: 7),
                      badge!,
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TOGGLE SETTING ───────────────────────────────────────────────────────────

class _ToggleSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final bool value;
  final void Function(bool) onChanged;
  final bool enabled;
  final String? disabledReason;

  const _ToggleSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && value;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.05)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon,
                      size: 18,
                      color: active ? AppTheme.primary : AppTheme.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          badge!,
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
                Switch(
                  value: active,
                  onChanged: enabled ? onChanged : null,
                  activeColor: AppTheme.primary,
                ),
              ],
            ),
            if (!enabled && disabledReason != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(disabledReason!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── PREMIUM BADGE ────────────────────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFF59E0B)]),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text('Premium',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── DATE TILE ────────────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
              color: value != null ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(10),
          color: value != null
              ? AppTheme.primary.withOpacity(0.04)
              : AppTheme.cardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_today,
                  size: 12,
                  color: value != null
                      ? AppTheme.primary
                      : AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: value != null
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(value ?? 'Set date & time',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
