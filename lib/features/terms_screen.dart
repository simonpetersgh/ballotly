// lib/features/info/presentation/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'info_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'Terms & Conditions',
      sections: [
        const InfoHighlight(
          'Please read these Terms and Conditions carefully before using EVoteHub. '
          'By accessing or using the platform, you confirm that you have read, understood, '
          'and agreed to be bound by these Terms. If you do not agree, you must not use '
          'the platform.\n\nLast updated: January 2025.',
        ),

        InfoSection(
          heading: '1. Acceptance of Terms',
          children: const [
            InfoParagraph(
              'These Terms and Conditions ("Terms") constitute a legally binding agreement '
              'between you ("User") and EVoteHub ("we", "us", "our"). They govern your '
              'access to and use of the EVoteHub platform, including all features, '
              'functionality, and services made available through it.',
            ),
            InfoParagraph(
              'We reserve the right to amend these Terms at any time. We will notify '
              'users of material changes by updating the "last updated" date. '
              'Your continued use of EVoteHub after any amendment constitutes '
              'acceptance of the revised Terms.',
            ),
          ],
        ),

        InfoSection(
          heading: '2. Eligibility',
          children: const [
            InfoParagraph('To use EVoteHub, you must:'),
            InfoBullet(
              'Be at least 13 years of age, or the minimum age required to form '
              'a binding agreement in your jurisdiction.',
            ),
            InfoBullet('Have the legal capacity to enter into a binding agreement.'),
            InfoBullet('Not be prohibited from using the service under applicable law.'),
            InfoBullet(
              'As a voter: be registered on the eligible voter list for the specific '
              'election you intend to participate in, as determined solely by the '
              'election organiser.',
            ),
          ],
        ),

        InfoSection(
          heading: '3. Accounts and Authentication',
          children: const [
            InfoParagraph(
              'EVoteHub uses a unified account model. Any registered account may '
              'both create elections and participate in elections as a voter. '
              'Your role in a given election is determined by context — you are '
              'an organiser for elections you create, and a voter for elections '
              'in which your email has been registered by an organiser.',
            ),
            InfoParagraph(
              'Voting without a registered account ("guest voting") is also supported, '
              'using an election code and the credentials assigned by the organiser.',
            ),
            InfoParagraph('When you create an account, you agree to:'),
            InfoBullet('Provide accurate, current, and complete information.'),
            InfoBullet(
              'Maintain the confidentiality of your authentication credentials, '
              'including one-time passwords (OTPs) and verification tokens.',
            ),
            InfoBullet(
              'Notify us immediately of any suspected unauthorised access to your account.',
            ),
            InfoBullet(
              'Accept responsibility for all activities conducted under your account.',
            ),
            InfoParagraph(
              'EVoteHub reserves the right to suspend or terminate accounts that '
              'violate these Terms, are found to contain materially false information, '
              'or are associated with fraudulent or abusive activity.',
            ),
          ],
        ),

        InfoSection(
          heading: '4. Permitted Use',
          children: const [
            InfoParagraph(
              'EVoteHub is provided for legitimate organisational voting purposes, '
              'including but not limited to: student union elections, corporate '
              'and board elections, community and association votes, cooperative '
              'governance elections, and internal institutional elections.',
            ),
            InfoParagraph('You may use EVoteHub to:'),
            InfoBullet(
              'Participate as a voter in elections for which you are a registered '
              'eligible voter, using the verification method configured by the organiser.',
            ),
            InfoBullet(
              'Create, configure, and manage elections on behalf of a legitimate '
              'organisation as an organiser.',
            ),
            InfoBullet(
              'View election results that are published and accessible to you.',
            ),
          ],
        ),

        InfoSection(
          heading: '5. Prohibited Conduct',
          children: const [
            InfoParagraph(
              'The following conduct is strictly prohibited and may result in '
              'immediate account termination and, where appropriate, legal action:',
            ),
            InfoBullet(
              'Attempting to cast more than one vote in any single election.',
            ),
            InfoBullet(
              'Impersonating another person or misrepresenting your identity or affiliation.',
            ),
            InfoBullet(
              'Using another person\'s verification tokens, OTP codes, or credentials '
              'to access a ballot on their behalf.',
            ),
            InfoBullet(
              'Interfering with or attempting to disrupt the operation of the platform, '
              'including through denial-of-service attacks, injection of malicious code, '
              'or exploitation of vulnerabilities.',
            ),
            InfoBullet(
              'Attempting to access data, accounts, or systems you are not authorised '
              'to access.',
            ),
            InfoBullet(
              'Using automated scripts, bots, or programmatic tools to interact with '
              'the platform, including for the purpose of mass account creation or '
              'automated voting.',
            ),
            InfoBullet(
              'Using the platform to conduct fraudulent, coercive, deceptive, '
              'or unlawful elections.',
            ),
            InfoBullet(
              'Reverse engineering, decompiling, disassembling, or attempting to '
              'derive the source code of the platform.',
            ),
            InfoBullet(
              'Reselling, sublicensing, or otherwise commercially exploiting access '
              'to the platform without our prior written consent.',
            ),
          ],
        ),

        InfoSection(
          heading: '6. Organiser Responsibilities',
          children: const [
            InfoParagraph(
              'If you use EVoteHub to create and manage elections, you additionally '
              'represent, warrant, and agree that:',
            ),
            InfoBullet(
              'You have the legitimate authority and organisational mandate to '
              'conduct the election.',
            ),
            InfoBullet(
              'The voter list you upload or create contains only individuals who '
              'have consented to participate and whose personal data — including '
              'name, email address, and verification token(s) — you are lawfully '
              'authorised to process.',
            ),
            InfoBullet(
              'Verification tokens you assign to voters are issued fairly, '
              'communicated to voters through appropriate channels, and not '
              'shared in a manner that enables voter impersonation.',
            ),
            InfoBullet(
              'You will not use EVoteHub to conduct elections that are deceptive, '
              'coercive, discriminatory, or in violation of any applicable law, '
              'regulation, or organisational constitution.',
            ),
            InfoBullet(
              'You are solely responsible for communicating the election code, '
              'voter credentials, and election schedule to eligible voters. '
              'EVoteHub does not send voter invitations or notifications on your behalf.',
            ),
            InfoBullet(
              'You acknowledge that EVoteHub provides platform infrastructure only '
              'and bears no responsibility for the governance, validity, or outcomes '
              'of elections conducted through the platform.',
            ),
          ],
        ),

        InfoSection(
          heading: '7. Free and Premium Features',
          children: const [
            InfoParagraph(
              'EVoteHub offers a free tier and premium-tier features for elections. '
              'The free tier includes core voting functionality and supports up to '
              '200 eligible voters per election.',
            ),
            InfoParagraph(
              'Premium features — including OTP verification, secondary token '
              'verification, and unlimited voter lists — are available on paid elections. '
              'Pricing and upgrade terms are presented within the platform at the '
              'point of upgrade.',
            ),
            InfoParagraph(
              'We reserve the right to modify the features included in each tier, '
              'with reasonable advance notice to active users.',
            ),
          ],
        ),

        InfoSection(
          heading: '8. Intellectual Property',
          children: const [
            InfoParagraph(
              'All content, features, and functionality of the EVoteHub platform — '
              'including its design, source code, graphics, logos, user interface, '
              'and written materials — are the exclusive property of EVoteHub and '
              'are protected by applicable intellectual property law.',
            ),
            InfoParagraph(
              'You are granted a limited, non-exclusive, non-transferable, '
              'revocable licence to access and use EVoteHub solely for its '
              'intended purpose as described in these Terms. No other rights or '
              'licences are granted, express or implied.',
            ),
          ],
        ),

        InfoSection(
          heading: '9. Disclaimer of Warranties',
          children: const [
            InfoHighlight(
              'EVoteHub is provided "as is" and "as available" without warranties '
              'of any kind, express or implied. We do not warrant that the platform '
              'will be uninterrupted, error-free, or free from malicious components.',
            ),
            InfoParagraph(
              'We make no warranties regarding the fitness of the platform for any '
              'particular purpose, its accuracy, reliability, or that it will meet '
              'the specific requirements of your organisation\'s electoral constitution '
              'or applicable law. Your use of EVoteHub is at your sole risk.',
            ),
          ],
        ),

        InfoSection(
          heading: '10. Limitation of Liability',
          children: const [
            InfoParagraph(
              'To the fullest extent permitted by applicable law, EVoteHub and its '
              'directors, officers, employees, agents, and licensors shall not be '
              'liable for any indirect, incidental, special, consequential, or '
              'punitive damages arising from your access to or use of (or inability '
              'to use) the platform, even if we have been advised of the possibility '
              'of such damages.',
            ),
            InfoParagraph(
              'In no event shall our total aggregate liability to you for any and all '
              'claims exceed the amount paid by you to EVoteHub in the twelve-month '
              'period immediately preceding the event giving rise to the claim.',
            ),
          ],
        ),

        InfoSection(
          heading: '11. Indemnification',
          children: const [
            InfoParagraph(
              'You agree to indemnify, defend, and hold harmless EVoteHub and its '
              'affiliates, officers, employees, and agents from and against any claims, '
              'liabilities, damages, losses, and expenses — including reasonable legal '
              'fees — arising out of or in connection with your use of the platform, '
              'your violation of these Terms, or your infringement of any third-party right.',
            ),
          ],
        ),

        InfoSection(
          heading: '12. Termination',
          children: const [
            InfoParagraph(
              'We reserve the right to suspend or terminate your access to EVoteHub '
              'at any time, with or without notice, for conduct that we reasonably '
              'believe violates these Terms, harms other users, or threatens the '
              'integrity of elections conducted on the platform.',
            ),
            InfoParagraph(
              'Upon termination, your licence to use the platform ceases immediately. '
              'Provisions of these Terms that by their nature should survive termination '
              'will do so, including Sections 5, 8, 9, 10, 11, and 13.',
            ),
          ],
        ),

        InfoSection(
          heading: '13. Governing Law and Disputes',
          children: const [
            InfoParagraph(
              'These Terms shall be governed by and construed in accordance with '
              'applicable law. Any dispute arising out of or in connection with these '
              'Terms or your use of EVoteHub that cannot be resolved through good-faith '
              'negotiation shall be submitted to the exclusive jurisdiction of the '
              'competent courts.',
            ),
          ],
        ),

        InfoSection(
          heading: '14. Severability',
          children: const [
            InfoParagraph(
              'If any provision of these Terms is found to be unlawful, void, or '
              'unenforceable, that provision shall be deemed severable from these Terms '
              'and shall not affect the validity and enforceability of the remaining provisions.',
            ),
          ],
        ),

        InfoSection(
          heading: '15. Contact',
          children: const [
            InfoParagraph('For questions or concerns regarding these Terms, please contact us:'),
            InfoBullet('Email: legal@evotehub.app'),
            InfoBullet('Response time: within 14 business days.'),
          ],
        ),
      ],
    );
  }
}
