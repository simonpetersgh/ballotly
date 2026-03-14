// lib/features/info/presentation/screens/howto_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'info_scaffold.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'How to Use EVoteHub',
      sections: [
        const InfoHighlight(
          'EVoteHub is designed to make electronic voting accessible and secure '
          'for any organisation. This guide covers everything you need — whether '
          'you are casting a vote or running an election.',
        ),

        // ── VOTER GUIDE ────────────────────────────────────────────────────────
        _RoleHeader(
          icon: Icons.how_to_vote_rounded,
          label: 'For Voters',
          color: AppTheme.primary,
        ),

        InfoSection(
          heading: 'How Voter Eligibility Works',
          children: const [
            InfoParagraph(
              'Your eligibility to vote is determined by the election organiser, '
              'not by EVoteHub. Before the election opens, the organiser adds your '
              'email address and a verification token to the voter list. You use '
              'these to access the ballot.',
            ),
            InfoParagraph(
              'EVoteHub supports two verification methods depending on how the '
              'organiser has configured the election:',
            ),
            InfoBullet(
              'Token Verification — you enter your email address plus a primary token '
              '(such as a student ID, membership number, or staff ID) to access the ballot. '
              'Some elections may require a secondary token for additional confirmation.',
            ),
            InfoBullet(
              'OTP Verification — you enter your email address and receive a one-time '
              'code by email to access the ballot. This method is available on elections '
              'that have enabled it.',
            ),
            InfoParagraph(
              'Your organiser will tell you which method applies and what token(s) to use. '
              'Contact them — not EVoteHub support — if you are unsure what to enter.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Voting as a Registered User',
          children: const [
            InfoParagraph(
              'If you have an EVoteHub account, elections you are eligible for '
              'will appear in the "Eligible Elections" section of your dashboard '
              'automatically, provided the organiser used the same email address '
              'as your account.',
            ),
            InfoStep(
              number: 1,
              title: 'Sign in to your account',
              body: 'From the home page, sign in with your email and password. '
                  'New users can register with the same organiser-provided email '
                  'address.',
            ),
            InfoStep(
              number: 2,
              title: 'Open your dashboard',
              body: 'After signing in you are taken to your dashboard. '
                  'The "Eligible Elections" section shows all elections your email '
                  'is registered for.',
            ),
            InfoStep(
              number: 3,
              title: 'Confirm your identity',
              body: 'Tap an active election. You will be asked to enter your '
                  'primary token (and secondary token if required) to confirm '
                  'you are the registered voter. This step is separate from your '
                  'account login.',
            ),
            InfoStep(
              number: 4,
              title: 'Cast your vote',
              body: 'Select one candidate per position on the ballot. You must '
                  'complete all positions before submitting. Review your selections '
                  'carefully — votes cannot be changed once submitted.',
            ),
            InfoStep(
              number: 5,
              title: 'Receive confirmation',
              body: 'A confirmation screen is shown after a successful submission. '
                  'Your vote is recorded immediately.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Voting as a Guest (No Account Required)',
          children: const [
            InfoParagraph(
              'You do not need an EVoteHub account to vote. From the home page, '
              'tap "Vote as Guest" and use the election code provided by your organiser.',
            ),
            InfoStep(
              number: 1,
              title: 'Go to "Vote as Guest"',
              body: 'Tap "Vote as Guest" on the EVoteHub home page.',
            ),
            InfoStep(
              number: 2,
              title: 'Choose your verification method',
              body: 'The default form uses Token Verification. '
                  'If your election uses OTP, tap "Use OTP verification instead" '
                  'below the Continue button to switch forms.',
            ),
            InfoStep(
              number: 3,
              title: 'Token Verification — enter your details',
              body: 'Enter the election code, your email address, your primary token, '
                  'and your secondary token if your organiser requires it. '
                  'All fields must match exactly what the organiser registered.',
            ),
            InfoStep(
              number: 4,
              title: 'OTP Verification — request your code',
              body: 'Enter the election code and your email address, then tap '
                  '"Send Verification Code". Check your email for a 6-digit code '
                  'and enter it on the next screen.',
            ),
            InfoStep(
              number: 5,
              title: 'Cast your vote',
              body: 'Once verified, you are taken directly to the ballot. '
                  'Select your candidates and submit.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Viewing Election Results',
          children: const [
            InfoParagraph(
              'Results are published automatically when an election closes. '
              'You can view them from your dashboard (Eligible Elections section) '
              'or publicly using the election code from the EVoteHub home page '
              '("View Results").',
            ),
            InfoBullet(
              'Results show vote counts and percentages for each candidate per position.',
            ),
            InfoBullet(
              'Your individual vote is never displayed — only aggregate tallies are shown.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Important Notes for Voters',
          children: const [
            InfoBullet(
              'You can only vote once per election. The system enforces this automatically.',
            ),
            InfoBullet(
              'Your vote is secret. The organiser can see that you voted but cannot '
              'see how you voted.',
            ),
            InfoBullet(
              'Token fields are case-sensitive and must match exactly what the organiser '
              'entered. Contact your organiser if your token is rejected.',
            ),
            InfoBullet(
              'OTP codes are valid for 10 minutes. Use the "Resend code" link if yours expires.',
            ),
            InfoBullet(
              'If you do not see an election you expect, confirm that your organiser '
              'used the exact same email address as your account.',
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 24),

        // ── ORGANISER GUIDE ────────────────────────────────────────────────────
        _RoleHeader(
          icon: Icons.admin_panel_settings_rounded,
          label: 'For Organisers',
          color: AppTheme.accent,
        ),

        InfoSection(
          heading: 'Getting Started',
          children: const [
            InfoParagraph(
              'Any EVoteHub account can create and manage elections. '
              'Register or sign in, then tap "New Election" from your dashboard '
              'to begin the guided 5-step setup.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Step 1 — Election Details & Verification Settings',
          children: const [
            InfoParagraph(
              'Enter the election title, an optional description, and the start '
              'and end date and time. Voting opens and closes automatically at '
              'these times.',
            ),
            InfoParagraph(
              'In the Verification Settings section, choose how voters will '
              'identify themselves:',
            ),
            InfoBullet(
              'Token Verification (free) — voters enter a primary token you assign '
              'them. Optionally enable a Secondary Token for a second confirmation '
              'factor. You communicate these tokens to voters out of band.',
            ),
            InfoBullet(
              'OTP Verification (premium) — voters receive a one-time email code '
              'instead of using a token. Higher assurance, no tokens to distribute.',
            ),
            InfoParagraph(
              'Both methods are fully accessible in the setup flow. '
              'Premium features are marked with a ⭐ badge.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Step 2 — Positions',
          children: const [
            InfoParagraph(
              'Add all contested positions (e.g. President, Treasurer, Secretary). '
              'Drag and drop to reorder them — the order here is the order they '
              'appear on the ballot.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Step 3 — Candidates',
          children: const [
            InfoParagraph(
              'For each position, add candidates with their name, optional bio, '
              'optional photo URL, and optional ballot number. Candidates with '
              'ballot numbers are sorted by that number on the ballot.',
            ),
            InfoBullet(
              'Each position must have at least two candidates before the election '
              'can be published.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Step 4 — Voters',
          children: const [
            InfoParagraph(
              'Add eligible voters individually or import a CSV file. '
              'Each voter record requires a name and email address at minimum.',
            ),
            InfoBullet(
              'For Token Verification elections, also enter the primary token '
              'for each voter (and secondary token if you enabled it). '
              'These are the credentials voters will use to access the ballot.',
            ),
            InfoBullet(
              'For OTP Verification elections, only name and email are needed — '
              'voters authenticate via email code.',
            ),
            InfoBullet(
              'Free elections support up to 200 voters. An informational banner '
              'appears when this threshold is reached. You can continue adding '
              'voters and upgrade before publishing.',
            ),
          ],
        ),

        InfoSection(
          heading: 'CSV Import',
          children: [
            const InfoParagraph(
              'Upload a CSV file with a header row. You will map which columns '
              'correspond to email, full name, primary token, and secondary token '
              'in the import flow. Extra columns are ignored.',
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                'id,full_name,email,student_id,dob\n'
                '1,Kwame Mensah,kwame@university.edu,STU-001,1999-04-12\n'
                '2,Ama Owusu,ama@university.edu,STU-002,2000-08-30\n'
                '3,Kofi Asante,kofi@university.edu,STU-003,2001-01-15',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const InfoBullet(
              'The import preview shows valid rows (will import) and invalid rows '
              '(will skip) before you confirm. Invalid rows are those with a missing '
              'or malformed email, or a missing name.',
            ),
            const InfoBullet(
              'Importing a voter whose email already exists on the list '
              'updates their record rather than creating a duplicate.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Step 5 — Review & Publish',
          children: const [
            InfoParagraph(
              'Review all election details before publishing. The review screen '
              'checks that all positions have at least two candidates and flags '
              'any incomplete setup.',
            ),
            InfoParagraph(
              'Publishing makes the election visible to eligible voters. '
              'Voting does not open until the configured start time.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Election Statuses',
          children: const [
            InfoBullet(
              'Draft — setup in progress. Not visible to voters.',
            ),
            InfoBullet(
              'Published — visible to eligible voters with the opening date shown. '
              'Voting is not yet open.',
            ),
            InfoBullet(
              'Active — voting is open. Eligible voters can cast their ballot.',
            ),
            InfoBullet(
              'Closed — voting has ended. Results are visible to all eligible voters '
              'and publicly via the election code.',
            ),
            InfoParagraph(
              'Status transitions happen automatically based on your configured '
              'schedule. You can also manually trigger transitions from the dashboard.',
            ),
          ],
        ),

        InfoSection(
          heading: 'Communicating with Voters',
          children: const [
            InfoParagraph(
              'EVoteHub does not send voter invitations or notifications on your '
              'behalf. You are responsible for communicating the following to your voters:',
            ),
            InfoBullet('The election code (for guest voting and public results).'),
            InfoBullet(
              'The email address they should use (must match what you registered).'),
            InfoBullet(
              'Their primary token — and secondary token if applicable '
              '(for Token Verification elections).',
            ),
            InfoBullet('The election start and end date and time.'),
          ],
        ),
      ],
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RoleHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}
