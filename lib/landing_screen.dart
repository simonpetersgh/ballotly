// lib/features/auth/presentation/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:myapp/core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _cardsFade;

  bool _registerExpanded = false;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    _cardsFade = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOut,
    );

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      endDrawer: _buildMobileDrawer(context), // ← add this
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNav(context, isWide),
            _buildHero(context, isWide),
            _buildFeatures(context, isWide),
            _buildAudience(context, isWide),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // NAV
  Widget _buildNav(BuildContext context, bool isWide) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.how_to_vote, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'Ballotly',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: isWide
          // ── Desktop ──────────────────────────────────────────────────────
          ? Row(
              children: [
                logo,
                const Spacer(),
                _NavButton(
                  label: 'View Results',
                  icon: Icons.bar_chart_rounded,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/voter'),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _NavButton(
                  label: 'Get Started',
                  primary: true,
                  onTap: () =>
                      setState(() => _registerExpanded = !_registerExpanded),
                ),
              ],
            )
          // ── Mobile: logo left, menu icon right ───────────────────────────
          : Row(
              children: [
                logo,
                const Spacer(),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(LineIcons.bars),
                    // icon: SvgPicture.asset(
                    //   'assets/icons/menu.svg',
                    //   width: 24,
                    //   height: 24,
                    //   colorFilter: const ColorFilter.mode(
                    //     AppTheme.textPrimary,
                    //     BlendMode.srcIn,
                    //   ),
                    // ),
                    color: AppTheme.textPrimary,
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.how_to_vote,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ballotly',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // ── Nav items ─────────────────────────────────────────────────
            _DrawerNavTile(
              icon: Icons.login_rounded,
              label: 'Login',
              onTap: () {
                Navigator.pop(context);
                context.go('/voter');
              },
            ),
            _DrawerNavTile(
              icon: Icons.how_to_vote_rounded,
              label: 'Vote Now',
              onTap: () {
                Navigator.pop(context);
                context.go('/vote');
              },
            ),
            _DrawerNavTile(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Register',
              onTap: () {
                Navigator.pop(context);
                context.go('/organiser/register');
              },
            ),
            _DrawerNavTile(
              icon: Icons.bar_chart_rounded,
              label: 'View Results',
              onTap: () {
                Navigator.pop(context);
                // TODO: /results
              },
            ),
          ],
        ),
      ),
    );
  }

  // HERO
  Widget _buildHero(BuildContext context, bool isWide) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 80 : 28,
            vertical: isWide ? 100 : 64,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FF), AppTheme.surface],
            ),
          ),
          child: Column(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Secure · Transparent · Simple',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Elections your\norganisation can trust',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 56 : 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),

              const SizedBox(height: 20),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: const Text(
                  'Ballotly makes it easy for organisations to run transparent, secure elections — and for voters to participate with confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              if (!_registerExpanded)
                _buildHeroCTAs(context)
              else
                _buildRegisterChoice(context),

              const SizedBox(height: 56),

              // Trust pills
              FadeTransition(
                opacity: _cardsFade,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: const [
                    _StatPill(
                      label: 'Encrypted',
                      subtitle: 'End-to-end vote security',
                      icon: Icons.lock_outline,
                    ),
                    _StatPill(
                      label: 'Auditable',
                      subtitle: 'Full audit log per election',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _StatPill(
                      label: 'Instant',
                      subtitle: 'Results in real time',
                      icon: Icons.bolt_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCTAs(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _HeroCTA(
          label: 'Get Started',
          icon: Icons.how_to_vote_outlined,
          primary: true,
          onTap: () => setState(() => _registerExpanded = true),
        ),
        _HeroCTA(
          label: 'Vote Now',
          icon: Icons.login_rounded,
          onTap: () => context.go('/'),
        ),
        _HeroCTA(
          label: 'View Results',
          icon: Icons.bar_chart_rounded,
          onTap: () {}, // TODO: /results
        ),
      ],
    );
  }

  Widget _buildRegisterChoice(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Who are you registering as?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _RegisterCard(
              icon: Icons.how_to_vote_outlined,
              title: 'Voter',
              subtitle: "I've been invited to\nparticipate in an election",
              color: AppTheme.primary,
              onTap: () => context.go('/voter'),
            ),
            _RegisterCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Organiser',
              subtitle: 'I want to create and\nmanage elections',
              color: AppTheme.accent,
              onTap: () => context.go('/organiser/register'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _registerExpanded = false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // FEATURES
  Widget _buildFeatures(BuildContext context, bool isWide) {
    final features = [
      (
        Icons.ballot_outlined,
        AppTheme.primary,
        'Multi-position elections',
        'Run complex elections with multiple positions and candidates in a single event.',
      ),
      (
        Icons.verified_user_outlined,
        AppTheme.success,
        'Eligibility control',
        'Only people you add can vote. Import your voter list by email — the system handles the rest.',
      ),
      (
        Icons.schedule_outlined,
        AppTheme.accent,
        'Scheduled & automated',
        'Set your election schedule and let it run. Elections open and close automatically.',
      ),
      (
        Icons.bar_chart_rounded,
        const Color(0xFFE07B39),
        'Live results',
        'Watch votes come in as they happen. Results are tallied in real time.',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 28, vertical: 72),
      color: AppTheme.cardBg,
      child: Column(
        children: [
          const Text(
            'Everything you need to\nrun a serious election',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Built for organisations that need more than a show of hands.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 52),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map(
                    (f) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _FeatureCard(
                          icon: f.$1,
                          color: f.$2,
                          title: f.$3,
                          body: f.$4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Column(
              children: features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FeatureCard(
                        icon: f.$1,
                        color: f.$2,
                        title: f.$3,
                        body: f.$4,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // AUDIENCE + BOTTOM CTA
  Widget _buildAudience(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 28, vertical: 72),
      color: AppTheme.surface,
      child: Column(
        children: [
          const Text(
            'Who is Ballotly for?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 40),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _AudienceChip(
                label: 'Student Unions',
                icon: Icons.school_outlined,
              ),
              _AudienceChip(
                label: 'Professional Associations',
                icon: Icons.business_center_outlined,
              ),
              _AudienceChip(
                label: 'Community Groups',
                icon: Icons.people_outline,
              ),
              _AudienceChip(
                label: 'Non-profits',
                icon: Icons.volunteer_activism_outlined,
              ),
              _AudienceChip(
                label: 'Corporate Boards',
                icon: Icons.corporate_fare_outlined,
              ),
              _AudienceChip(
                label: 'Faith Communities',
                icon: Icons.favorite_border,
              ),
            ],
          ),
          const SizedBox(height: 56),

          // Bottom gradient CTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Ready to run your first election?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Set up takes minutes. Your voters just need their email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/organiser/register'),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Get Started as Organiser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/voter'),
                      icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                      label: const Text('Register as Voter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FOOTER
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.how_to_vote, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          const Text(
            'Ballotly',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            '© ${DateTime.now().year} Ballotly',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── REUSABLE COMPONENTS ──────────────────────────────────────────────────────

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
      horizontalTitleGap: 8,
      onTap: onTap,
    );
  }
}

// ignore: unused_element
class _MobileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MobileMenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;

  const _NavButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 15) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        side: BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _HeroCTA extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _HeroCTA({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: BorderSide(color: AppTheme.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RegisterCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AudienceChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
