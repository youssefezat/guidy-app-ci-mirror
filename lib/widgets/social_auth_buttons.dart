import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/social_auth_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class SocialAuthButtons extends StatefulWidget {
  const SocialAuthButtons({super.key});

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool _loading = false;

  Future<void> _handle(String provider, Future<SocialAuthResult> Function() signIn) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);

    final result = await signIn();

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.credential != null) {
      final isNewUser = result.credential!.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        AnalyticsService.logSignUp(provider);
      } else {
        AnalyticsService.logSignIn(provider);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? l10n.socialSignInFailed), backgroundColor: Colors.red),
      );
    }
    // Cancelled: no message, the person just closed the picker.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: context.isDark ? Colors.white24 : Colors.black12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.orDivider, style: TextStyle(color: context.textSecondary)),
            ),
            Expanded(child: Divider(color: context.isDark ? Colors.white24 : Colors.black12)),
          ],
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : () => _handle('google', SocialAuthService.signInWithGoogle),
            icon: const FaIcon(FontAwesomeIcons.google, size: 18, color: Color(0xFFEA4335)),
            label: Text(l10n.continueWithGoogle, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: context.isDark ? Colors.white24 : Colors.black26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: _loading ? null : () => _handle('anonymous', SocialAuthService.signInAsGuest),
          child: Text(l10n.continueAsGuest, style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
        ),

        if (_loading) ...[
          const SizedBox(height: 16),
          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal)),
        ],
      ],
    );
  }
}
