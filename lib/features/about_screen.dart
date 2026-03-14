// lib/features/info/presentation/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'info_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'About & Support',
      sections: [

        // ── Brand hero ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.how_to_vote_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('EVoteHub',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text(
                'Secure, transparent electronic voting for organisations of any size.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Version 1.0.0',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        InfoSection(
          heading: 'What is EVoteHub?',
          children: const [
            InfoParagraph(
              'EVoteHub is an electronic voting platform built for organisations '
              'that want to run fair, credible elections — without the hassle. '
              'Whether you\'re a student union, a professional association, a '
              'cooperative, a faith community, or any group that holds elections, '
              'EVoteHub gives you the tools to do it properly.',
            ),
            InfoParagraph(
              'We believe every organisation deserves access to a professional '
              'voting process — not just large institutions with dedicated IT teams. '
              'EVoteHub is designed to be usable by anyone, from setup to final results.',
            ),
          ],
        ),

        InfoSection(
          heading: 'How It Works',
          children: const [
            InfoParagraph(
              'Organisers set up an election in minutes — adding positions, '
              'candidates, and the eligible voter list. Voters receive their '
              'credentials from the organiser and use them to access the ballot, '
              'either through their EVoteHub account or as a guest with just '
              'an election code.',
            ),
            InfoParagraph(
              'Voting is open for exactly as long as the organiser sets. '
              'Once the election closes, results are published instantly '
              'and accessible to all eligible voters.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Why Organisations Trust Us',
          children: const [
            InfoBullet(
              'Your vote is completely secret — no one, including the organiser, '
              'can ever see how you voted.',
            ),
            InfoBullet(
              'The system prevents anyone from voting more than once.',
            ),
            InfoBullet(
              'Results are calculated automatically and displayed transparently '
              'with full vote counts and percentages.',
            ),
            InfoBullet(
              'No software to install — works on any phone, tablet, or computer.',
            ),
            InfoBullet(
              'Voters don\'t need an account — they can participate as guests '
              'using a simple election code.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Who Uses EVoteHub?',
          children: const [
            InfoParagraph(
              'EVoteHub is used by student unions, professional bodies, '
              'cooperative societies, religious organisations, NGOs, corporate '
              'boards, and community groups across the world. If your organisation '
              'holds elections, EVoteHub was built for you.',
            ),
          ],
        ),

        const Divider(height: 48),

        InfoSection(
          heading: 'Contact & Support',
          children: const [
            InfoParagraph(
              'We\'re here to help. Whether you need guidance setting up an '
              'election, have a question about how voting works, or need to '
              'make a data or legal request — reach out and we\'ll get back '
              'to you promptly.',
            ),
          ],
        ),

        InfoContactTile(
          icon: Icons.email_outlined,
          label: 'General Support',
          value: 'support@evotehub.app',
        ),
        InfoContactTile(
          icon: Icons.security_rounded,
          label: 'Privacy & Data Requests',
          value: 'privacy@evotehub.app',
        ),
        InfoContactTile(
          icon: Icons.gavel_rounded,
          label: 'Legal & Terms',
          value: 'legal@evotehub.app',
        ),
        InfoContactTile(
          icon: Icons.bug_report_outlined,
          label: 'Report a Bug',
          value: 'bugs@evotehub.app',
        ),

        const SizedBox(height: 8),

        InfoSection(
          heading: 'Response Times',
          children: const [
            InfoBullet('General support: within 2 business days.'),
            InfoBullet('Urgent election issues: within 4 hours during business hours.'),
            InfoBullet('Privacy and data requests: within 30 days as required by law.'),
            InfoBullet('Bug reports: acknowledged within 1 business day.'),
          ],
        ),

        InfoSection(
          heading: 'Before You Contact Us',
          children: [
            const InfoParagraph(
              'Many common questions are answered in the How To guide — '
              'it covers voting, guest access, election setup, and more.',
            ),
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => ctx.go('/how-to'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Read the How To Guide →',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        InfoSection(
          heading: 'Legal',
          children: [
            Builder(
              builder: (ctx) => Row(
                children: [
                  GestureDetector(
                    onTap: () => ctx.go('/privacy'),
                    child: const Text('Privacy Policy',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => ctx.go('/terms'),
                    child: const Text('Terms & Conditions',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
