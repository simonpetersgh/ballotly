// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:myapp/features/elections/election_details.dart';
import 'package:myapp/features/elections/elections_screen.dart';
import 'package:myapp/features/results/results_screen.dart';
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
        '/voter/login',
        '/voter/register',
        '/organiser/login',
        '/organiser/register',
        '/otp',
      ];
      final isPublic = publicRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      if (!isLoggedIn && !isPublic) return '/';
      if (isLoggedIn && state.matchedLocation == '/') {
        // Route based on account type
        final profile = await ref.read(currentUserProfileProvider.future);
        if (profile?.isOrganiser == true) return '/admin';
        return '/elections';
      }
      return null;
    },
    routes: [
      // ── Public ────────────────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),

      // Replace the old separate voter routes with the unified one
      GoRoute(path: '/voter', builder: (_, __) => const VoterAuthScreen()),
      GoRoute(
        path: '/voter/profile',
        builder: (_, __) => const VoterProfileScreen(),
      ),

      // GoRoute(
      //   path: '/voter/login',
      //   builder: (_, __) => const VoterLoginScreen(),
      // ),
      // GoRoute(
      //   path: '/voter/register',
      //   builder: (_, __) => const VoterRegisterScreen(),
      // ),
      // Keep organiser routes
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

      // ── Voter shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => VoterShell(child: child),
        routes: [
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

// class VoterShell extends ConsumerWidget {
//   final Widget child;
//   const VoterShell({super.key, required this.child});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [AppTheme.primary, AppTheme.accent],
//                 ),
//                 borderRadius: BorderRadius.circular(7),
//               ),
//               child: const Icon(
//                 Icons.how_to_vote,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//             const SizedBox(width: 10),
//             Flexible(child: const Text(overflow: TextOverflow.ellipsis, 'EVoteHub')),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Sign out',
//             onPressed: () async {
//               await ref.read(supabaseServiceProvider).signOut();
//               if (context.mounted) context.go('/');
//             },
//           ),
//         ],
//       ),
//       body: child,
//     );
//   }
// }

// // ─── ADMIN SHELL ──────────────────────────────────────────────────────────────

// class AdminShell extends ConsumerWidget {
//   final Widget child;
//   const AdminShell({super.key, required this.child});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [AppTheme.accent, AppTheme.primary],
//                 ),
//                 borderRadius: BorderRadius.circular(7),
//               ),
//               child: const Icon(
//                 Icons.admin_panel_settings,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//             const SizedBox(width: 10),
//             Flexible(child: const Text(overflow: TextOverflow.ellipsis, 'EVoteHub Admin')),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Sign out',
//             onPressed: () async {
//               await ref.read(supabaseServiceProvider).signOut();
//               if (context.mounted) context.go('/');
//             },
//           ),
//         ],
//       ),
//       body: child,
//     );
//   }
// }

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
      appBar: _shellAppBar(
        isAdmin: false,
        isMobile: isMobile,
        signOut: signOut,
      ),
      drawer: isMobile
          ? _AppDrawer(name: name, isAdmin: false, onSignOut: signOut)
          : null,
      body: child,
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
      appBar: _shellAppBar(isAdmin: true, isMobile: isMobile, signOut: signOut),
      drawer: isMobile
          ? _AppDrawer(name: name, isAdmin: true, onSignOut: signOut)
          : null,
      body: child,
    );
  }
}

// ─── SHARED APP BAR ───────────────────────────────────────────────────────────

AppBar _shellAppBar({
  required bool isAdmin,
  required bool isMobile,
  required Future<void> Function() signOut,
}) {
  return AppBar(
    automaticallyImplyLeading: isMobile,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdmin
                  ? [AppTheme.accent, AppTheme.primary]
                  : [AppTheme.primary, AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.how_to_vote,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isAdmin ? 'EVoteHub Admin' : 'EVoteHub',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
    // On mobile sign out is in the drawer — keep appbar clean
    actions: isMobile
        ? null
        : [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: signOut,
            ),
          ],
  );
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
                    'EVoteHub',
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
                        'Admin',
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
