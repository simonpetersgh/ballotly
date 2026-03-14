// lib/features/auth/presentation/screens/voter_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/shared_widgets.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/shared_widgets.dart';
import 'auth_widgets.dart';

class VoterProfileScreen extends ConsumerStatefulWidget {
  const VoterProfileScreen({super.key});

  @override
  ConsumerState<VoterProfileScreen> createState() => _VoterProfileScreenState();
}

class _VoterProfileScreenState extends ConsumerState<VoterProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // await ref.read(supabaseServiceProvider).createUserProfile(
      //   fullName: _nameCtrl.text.trim(),
      //   // accountType: SupabaseConstants.accountTypeVoter,
      // );
      if (mounted) context.go('/elections');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthLogo(),
            const SizedBox(height: 40),

            // Welcome icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand,
                color: AppTheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'One last step',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us your name so organisers can identify you on the voter list.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            if (_error != null) AuthErrorBanner(message: _error!),

            AppTextField(
              label: 'Full name',
              controller: _nameCtrl,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Full name is required';
                if (v.trim().split(' ').length < 2)
                  return 'Please enter your first and last name';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: _save,
              loading: _loading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
