// lib/shared/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── RESPONSIVE UTILITIES ─────────────────────────────────────────────────────

class Responsive {
  static const double mobileBreak = 600;
  static const double desktopBreak = 960;
  static const double contentMax = 880;   // max width for content pages
  static const double formMax = 540;      // max width for form/setup pages

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreak;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreak;

  /// Horizontal page padding — tighter on mobile, generous on desktop
  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 40);
    if (!isMobile(context)) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 16);
  }
}

/// Centers content with a max-width on desktop. Drop-in for most screen bodies.
class ResponsiveScaffoldBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveScaffoldBody({
    super.key,
    required this.child,
    this.maxWidth = Responsive.contentMax,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ─── CANDIDATE AVATAR ─────────────────────────────────────────────────────────

/// Shows candidate photo or styled initials fallback.
/// Overlays a ballot number badge when [ballotNumber] is set.
class CandidateAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int? ballotNumber;
  final double size;
  final Color color;

  const CandidateAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.ballotNumber,
    this.size = 52,
    this.color = AppTheme.primary,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials_(color),
                  )
                : _initials_(color),
          ),
        ),
        if (ballotNumber != null)
          Positioned(
            bottom: -3,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$ballotNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials_(Color c) => Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      );
}

// ─── APP BUTTON ───────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white))
        : icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label)
              ])
            : Text(label);

    final btn = outlined
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : ElevatedButton(onPressed: loading ? null : onPressed, child: child);

    return width != null ? SizedBox(width: width, child: btn) : btn;
  }
}

// ─── APP TEXT FIELD ───────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLines;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}

// ─── LOADING STATE ────────────────────────────────────────────────────────────

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─── ERROR STATE ──────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(label: 'Retry', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── STATUS CHIP ─────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppTheme.success;
        label = '● Active';
        break;
      case 'published':
        color = AppTheme.warning;
        label = 'Published';
        break;
      case 'draft':
        color = AppTheme.textMuted;
        label = 'Draft';
        break;
      case 'closed':
        color = AppTheme.danger;
        label = 'Closed';
        break;
      default:
        color = AppTheme.textMuted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// Light version for dark/gradient backgrounds
class StatusChipLight extends StatelessWidget {
  final String status;
  const StatusChipLight({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (status) {
      case 'active':
        label = '● Live';
        break;
      case 'published':
        label = 'Upcoming';
        break;
      case 'closed':
        label = 'Ended';
        break;
      default:
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}


// ─── STEP NAV BAR (election setup steps) ─────────────────────────────────────

class StepNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  const StepNavBar({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardBg,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: nextLabel,
              onPressed: onNext,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
