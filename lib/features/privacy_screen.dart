// lib/features/info/presentation/screens/privacy_screen.dart
import 'package:flutter/material.dart';
import 'info_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'Privacy Policy',
      sections: [
        const InfoHighlight(
          'This Privacy Policy explains how EVoteHub collects, uses, stores, '
          'and protects your personal information when you use our electronic '
          'voting platform. By using EVoteHub, you agree to the practices '
          'described in this policy.\n\nLast updated: January 2025.',
        ),

        InfoSection(
          heading: '1. Who We Are',
          children: const [
            InfoParagraph(
              'EVoteHub is an electronic voting platform that enables organisations, '
              'institutions, and groups to conduct secure, transparent, and auditable '
              'elections online. We are committed to responsible data stewardship and '
              'to protecting your privacy in full compliance with applicable data '
              'protection legislation.',
            ),
            InfoParagraph(
              'For any questions relating to this policy or the handling of your '
              'personal data, please contact: privacy@evotehub.app.',
            ),
          ],
        ),

        InfoSection(
          heading: '2. Categories of Information We Collect',
          children: const [
            InfoParagraph(
              'We collect only the information necessary to operate the platform '
              'securely and effectively:',
            ),
            InfoBullet(
              'Account information — your full name and email address, provided '
              'when you register an account.',
            ),
            InfoBullet(
              'Voter eligibility data — your name, email address, and verification '
              'token(s) as entered by the election organiser when you are added to '
              'a voter list. This data is processed on behalf of the organiser.',
            ),
            InfoBullet(
              'Authentication data — one-time passwords (OTPs) and session tokens '
              'used to verify your identity at sign-in or during guest verification. '
              'OTP codes are not stored in plain text and expire after a short window.',
            ),
            InfoBullet(
              'Participation records — a record confirming that you have cast a vote '
              'in a specific election, used to prevent duplicate voting. Your specific '
              'vote choices are not linked to your identity in any retrievable form.',
            ),
            InfoBullet(
              'Technical and audit data — IP addresses, browser type, device type, '
              'and access timestamps, retained for security monitoring and election '
              'integrity purposes.',
            ),
          ],
        ),

        InfoSection(
          heading: '3. How We Use Your Information',
          children: const [
            InfoParagraph('We process your information for the following purposes:'),
            InfoBullet('Creating and managing your account on the platform.'),
            InfoBullet('Verifying your identity when signing in or accessing a ballot.'),
            InfoBullet(
              'Determining your eligibility to participate in specific elections, '
              'based on voter lists provided by election organisers.',
            ),
            InfoBullet('Recording and tallying votes accurately and transparently.'),
            InfoBullet(
              'Sending transactional communications such as OTP verification codes. '
              'We do not send marketing emails.',
            ),
            InfoBullet(
              'Maintaining audit logs to support election integrity, dispute resolution, '
              'and legal compliance.',
            ),
            InfoBullet(
              'Improving platform security and performance based on anonymised and '
              'aggregated usage patterns.',
            ),
            InfoParagraph(
              'We do not use your information for advertising purposes. '
              'We do not sell, rent, or otherwise transfer your personal data to '
              'third parties for their own commercial use.',
            ),
          ],
        ),

        InfoSection(
          heading: '4. Vote Secrecy',
          children: const [
            InfoHighlight(
              'Your vote is secret. EVoteHub is architected so that while the system '
              'records that you have voted (to prevent duplicate voting), your specific '
              'candidate selections cannot be traced back to your identity by any '
              'organiser, administrator, or third party.',
            ),
            InfoParagraph(
              'Election results display aggregate tallies only. No per-voter vote '
              'breakdown is exposed to organisers, other voters, or the public. '
              'This guarantee applies equally to registered account holders and '
              'to voters who participate as guests.',
            ),
          ],
        ),

        InfoSection(
          heading: '5. Organiser Access to Voter Data',
          children: const [
            InfoParagraph(
              'Election organisers have access to the voter list they created, '
              'including names, email addresses, and verification tokens they '
              'entered. Organisers can see which voters on their list have cast '
              'a vote (participation status), but they cannot see how any voter voted.',
            ),
            InfoParagraph(
              'If you are added to an election voter list by an organiser, your '
              'name, email, and token data are visible to that organiser within '
              'the context of their election only.',
            ),
          ],
        ),

        InfoSection(
          heading: '6. Data Sharing and Sub-processors',
          children: const [
            InfoParagraph('We share your data only in the following circumstances:'),
            InfoBullet(
              'Infrastructure providers — we use Supabase as our backend infrastructure '
              'provider for database hosting and authentication services. Supabase '
              'processes your data on our behalf under a data processing agreement '
              'and does not use your data for its own purposes.',
            ),
            InfoBullet(
              'Legal obligations — we may disclose personal data if required to do so '
              'by a valid court order, subpoena, legal process, or applicable law, '
              'or where disclosure is necessary to protect the rights, property, or '
              'safety of EVoteHub, its users, or the public.',
            ),
            InfoBullet(
              'Business transfers — in the event of a merger, acquisition, or sale of '
              'assets, personal data may be transferred as part of that transaction, '
              'subject to equivalent privacy protections.',
            ),
          ],
        ),

        InfoSection(
          heading: '7. Data Retention',
          children: const [
            InfoParagraph(
              'We retain account information for as long as your account remains active. '
              'If you request deletion of your account, your profile and associated '
              'personal data will be removed within a reasonable timeframe.',
            ),
            InfoParagraph(
              'Election data — including voter lists, participation records, vote tallies, '
              'and audit logs — is retained for a minimum of 12 months after an election '
              'closes, to support auditing, dispute resolution, and compliance purposes.',
            ),
            InfoParagraph(
              'Anonymised vote records and audit logs may be retained beyond the account '
              'deletion period to preserve election integrity. These records cannot be '
              'used to identify your specific vote choices.',
            ),
          ],
        ),

        InfoSection(
          heading: '8. Data Security',
          children: const [
            InfoParagraph(
              'We implement industry-standard technical and organisational measures '
              'to protect your data:',
            ),
            InfoBullet(
              'All data in transit is encrypted using TLS (HTTPS). '
              'Unencrypted connections are not accepted.',
            ),
            InfoBullet(
              'Authentication uses short-lived one-time passwords with automatic expiry.',
            ),
            InfoBullet(
              'Database access is governed by Row Level Security (RLS) policies, '
              'enforced server-side using security-definer functions to prevent '
              'cross-user and cross-election data access.',
            ),
            InfoBullet(
              'Administrative access to infrastructure is strictly controlled, '
              'logged, and subject to multi-factor authentication.',
            ),
            InfoParagraph(
              'While we take all reasonable steps to protect your data, no system '
              'can guarantee absolute security. We encourage you to keep your OTP '
              'codes private and to report any suspected security incident to '
              'security@evotehub.app immediately.',
            ),
          ],
        ),

        InfoSection(
          heading: '9. Your Rights',
          children: const [
            InfoParagraph(
              'Subject to applicable law, you have the following rights with respect '
              'to your personal data:',
            ),
            InfoBullet('Right of access — to obtain a copy of the data we hold about you.'),
            InfoBullet('Right to rectification — to request correction of inaccurate data.'),
            InfoBullet(
              'Right to erasure — to request deletion of your account and personal data, '
              'subject to our retention obligations.',
            ),
            InfoBullet(
              'Right to restriction — to request that we limit the processing of your data '
              'in certain circumstances.',
            ),
            InfoBullet(
              'Right to data portability — to receive your data in a structured, '
              'machine-readable format.',
            ),
            InfoBullet(
              'Right to object — to object to processing carried out on the basis of '
              'legitimate interests.',
            ),
            InfoParagraph(
              'To exercise any of these rights, contact privacy@evotehub.app. '
              'We will acknowledge your request within 5 business days and respond '
              'in full within 30 days, or within the timeframe required by applicable law.',
            ),
          ],
        ),

        InfoSection(
          heading: '10. Cookies and Local Storage',
          children: const [
            InfoParagraph(
              'EVoteHub uses session-scoped storage in your browser solely to '
              'maintain your authenticated session. We do not use tracking cookies, '
              'advertising cookies, fingerprinting, or third-party analytics scripts. '
              'No data is shared with advertising networks.',
            ),
          ],
        ),

        InfoSection(
          heading: '11. International Data Transfers',
          children: const [
            InfoParagraph(
              'Your data may be processed and stored in data centres located outside '
              'your country of residence, including in the European Union and the '
              'United States, by our infrastructure sub-processors. Where such transfers '
              'occur, we ensure that appropriate safeguards are in place in accordance '
              'with applicable data protection law.',
            ),
          ],
        ),

        InfoSection(
          heading: '12. Changes to This Policy',
          children: const [
            InfoParagraph(
              'We may update this Privacy Policy from time to time to reflect changes '
              'in our practices or applicable law. We will update the "last updated" '
              'date at the top of this document when we do. We encourage you to review '
              'this policy periodically. Your continued use of EVoteHub after any '
              'changes are posted constitutes your acceptance of the updated policy.',
            ),
          ],
        ),

        InfoSection(
          heading: '13. Contact',
          children: const [
            InfoParagraph('For privacy-related questions or requests, please contact us:'),
            InfoBullet('Email: privacy@evotehub.app'),
            InfoBullet('Response time: within 30 days as required by applicable law.'),
          ],
        ),
      ],
    );
  }
}
