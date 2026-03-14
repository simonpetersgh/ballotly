// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:myapp/core/constants/app_constants.dart';
import 'package:myapp/core/models/models.dart';
import 'package:myapp/features/about_screen.dart';
import 'package:myapp/features/admin/admin_dashboard_screen.dart';
import 'package:myapp/features/admin/admin_election_voters_screen.dart';
import 'package:myapp/features/admin/election_setup_shell.dart';
import 'package:myapp/features/auth/organiser_login_screen.dart';
import 'package:myapp/features/auth/organiser_register_screen.dart';
import 'package:myapp/features/auth/otp_screen.dart';
import 'package:myapp/features/auth/voter_auth_screen.dart';
import 'package:myapp/features/auth/voter_login_screen.dart';
import 'package:myapp/features/auth/voter_profile_setup.dart';
import 'package:myapp/features/auth/voter_register_screen.dart';
import 'package:myapp/features/dashboard.dart';
import 'package:myapp/features/elections/election_details.dart';
import 'package:myapp/features/elections/elections_screen.dart';
import 'package:myapp/features/elections/get_ballot_screen.dart';
import 'package:myapp/features/elections/public_results_screen.dart';
import 'package:myapp/features/guest_entry_page.dart';
import 'package:myapp/features/guest_opt_verification_page.dart';
import 'package:myapp/features/howto_screen.dart';
import 'package:myapp/features/privacy_screen.dart';
import 'package:myapp/features/results/results_screen.dart';
import 'package:myapp/features/terms_screen.dart';
import 'package:myapp/features/voting/voting_screen.dart';
import 'package:myapp/landing_screen.dart';
import '../providers/providers.dart';
import '../../core/theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final authAsync = ref.read(authStateProvider);
      final session = authAsync.value?.session;
      final isLoggedIn = session != null;

      final publicRoutes = [
        '/',
        '/voter/',
        '/voter/login',
        '/voter/register',
        '/organiser/login',
        '/organiser/register',
        '/otp',
        '/privacy',
        '/terms',
        '/how-to',
        '/about',
        '/guest',
        '/results',
      ];

      final isPublic = publicRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      // Not logged in and trying to access a protected route
      if (!isLoggedIn && !isPublic) return '/';

      // if (isLoggedIn && state.matchedLocation == '/') {
      //   // Route based on account type
      //   final profile = await ref.read(currentUserProfileProvider.future);
      //   if (profile?.isOrganiser == true) return '/admin';
      //   return '/elections';
      // }

      // // Logged in and hitting a public/landing route — route by role
      // if (isLoggedIn && isPublic) {
      //   final profile = await ref.read(currentUserProfileProvider.future);
      //   if (profile?.isOrganiser == true) return '/admin';
      //   return '/elections';
      // }

      if (isLoggedIn && state.matchedLocation == '/') {
        // All logged-in users go to the unified dashboard.
        return '/dashboard';
      }
      return null;
    },

    routes: [
      // ── Public ────────────────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/how-to', builder: (_, __) => const HowToScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      // ── Guest voting ──────────────────────────────────────────────────────
      GoRoute(path: '/guest', builder: (_, __) => const GuestEntryScreen()),
      GoRoute(
        path: '/guest/:electionId',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return GuestBallotScreen(
            electionId: state.pathParameters['electionId']!,
            voterId: extra['voterId'] ?? '',
            voterEmail: extra['email'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/guest/otp-verify',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GuestOtpVerifyScreen(
            election: extra['election'] as ElectionModel,
            voter: extra['voter'] as VoterModel,
            email: extra['email'] as String,
          );
        },
      ),

      // ── Public results ────────────────────────────────────────────────────
      GoRoute(
        path: '/results/:electionId',
        builder: (_, state) => PublicResultsScreen(
          electionId: state.pathParameters['electionId']!,
        ),
      ),

      // ------ AUTH ROUTES -------
      // Replace the old separate voter routes with the unified one
      GoRoute(path: '/voter', builder: (_, __) => const VoterAuthScreen()),
      GoRoute(
        path: '/voter/profile',
        builder: (_, __) => const VoterProfileScreen(),
      ),
      GoRoute(
        path: '/voter/login',
        builder: (_, __) => const VoterLoginScreen(),
      ),
      GoRoute(
        path: '/voter/register',
        builder: (_, __) => const VoterRegisterScreen(),
      ),
      GoRoute(
        path: '/organiser/login',
        builder: (_, __) => const OrganiserLoginScreen(),
      ),
      GoRoute(
        path: '/organiser/register',
        builder: (_, __) => const OrganiserRegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(
          email: state.uri.queryParameters['email'] ?? '',
          fullName: state.uri.queryParameters['name'],
          mode: state.uri.queryParameters['mode'] ?? 'voter_login',
        ),
      ),
      // /////////

      // ── Voter shell ───────────────────────────────────────────────────────
      // ── Unified shell (all logged-in users)
      ShellRoute(
        builder: (context, state, child) => VoterShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/elections',
            builder: (_, __) => const ElectionsScreen(),
          ),
          GoRoute(
            path: '/elections/:id',
            builder: (_, state) =>
                ElectionDetailScreen(electionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/elections/:id/confirm',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return VoterTokenConfirmScreen(
                electionId: state.pathParameters['id']!,
                voter: extra['voter'] as VoterModel,
              );
            },
          ),
          GoRoute(
            path: '/elections/:id/vote',
            builder: (_, state) =>
                VotingScreen(electionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/elections/:id/results',
            builder: (_, state) =>
                ResultsScreen(electionId: state.pathParameters['id']!),
          ),
        ],
      ),

      // ── Admin shell ───────────────────────────────────────────────────────
      // ── Admin shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          // Election setup — multi-step, takes electionId (null = new)
          GoRoute(
            path: '/admin/elections/new',
            builder: (_, __) => const ElectionSetupShell(electionId: null),
          ),
          GoRoute(
            path: '/admin/elections/:id/setup',
            builder: (_, state) => ElectionSetupShell(
              electionId: state.pathParameters['id'],
              initialStep:
                  int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0,
            ),
          ),
          GoRoute(
            path: '/admin/elections/:id/voters',
            builder: (_, state) => AdminElectionVotersScreen(
              electionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/elections/:id/results',
            builder: (_, state) =>
                ResultsScreen(electionId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

// ─── VOTER SHELL ──────────────────────────────────────────────────────────────
// ─── VOTER SHELL ──────────────────────────────────────────────────────────────
// ─── VOTER SHELL ──────────────────────────────────────────────────────────────
// ─── VOTER SHELL ──────────────────────────────────────────────────────────────

class VoterShell extends ConsumerWidget {
  final Widget child;
  const VoterShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 960;
    final name = ref.watch(currentUserProfileProvider).value?.fullName ?? '';

    Future<void> signOut() async {
      await ref.read(supabaseServiceProvider).signOut();
      if (context.mounted) context.go('/');
    }

    return Scaffold(
      endDrawer: isMobile
          ? _AppDrawer(name: name, isAdmin: false, onSignOut: signOut)
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _ShellNav(isAdmin: false, isMobile: isMobile, signOut: signOut),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─── ADMIN SHELL ──────────────────────────────────────────────────────────────

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 960;
    final name = ref.watch(currentUserProfileProvider).value?.fullName ?? '';

    Future<void> signOut() async {
      await ref.read(supabaseServiceProvider).signOut();
      if (context.mounted) context.go('/');
    }

    return Scaffold(
      endDrawer: isMobile
          ? _AppDrawer(name: name, isAdmin: true, onSignOut: signOut)
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _ShellNav(isAdmin: true, isMobile: isMobile, signOut: signOut),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─── CUSTOM SHELL NAV ─────────────────────────────────────────────────────────

class _ShellNav extends StatelessWidget {
  final bool isAdmin;
  final bool isMobile;
  final Future<void> Function() signOut;

  const _ShellNav({
    required this.isAdmin,
    required this.isMobile,
    required this.signOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Logo icon
          // AppLogo(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [AppTheme.accent, AppTheme.primary]
                    : [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.how_to_vote,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAdmin ? 'Ballotly Orgainiser' : 'Ballotly',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const Spacer(),

          // Desktop — sign out inline
          if (!isMobile)
            TextButton.icon(
              onPressed: signOut,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),

          // Mobile — menu icon opens right drawer
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(LineIcons.bars),

                // icon: SvgPicture.asset(
                //   'assets/icons/menu.svg',
                //   width: 24,
                //   height: 24,
                //   // color: AppTheme.textPrimary,
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
}

// ─── APP DRAWER (mobile only) ─────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String name;
  final bool isAdmin;
  final Future<void> Function() onSignOut;

  const _AppDrawer({
    required this.name,
    required this.isAdmin,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.how_to_vote,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ballotly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Organiser',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Nav items
            if (!isAdmin) ...[
              _DrawerTile(
                icon: Icons.ballot_outlined,
                label: 'My Elections',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/elections');
                },
              ),
            ] else ...[
              _DrawerTile(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
              _DrawerTile(
                icon: Icons.add_circle_outline,
                label: 'New Election',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/elections/new');
                },
              ),
            ],

            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 4),

            // Sign out
            _DrawerTile(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppTheme.danger,
              onTap: () async {
                Navigator.pop(context);
                await onSignOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      horizontalTitleGap: 8,
      onTap: onTap,
    );
  }
}
