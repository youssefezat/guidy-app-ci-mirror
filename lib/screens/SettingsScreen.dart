import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import '../services/theme_controller.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/account_service.dart';
import '../services/social_auth_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const SettingsScreen({super.key, this.onGoHome});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _contactEmail = 'guidygroup@gmail.com';

  Future<void> _launchContactEmail(AppLocalizations l10n) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: {'subject': 'Guidy — '},
    );
    final launched = await launchUrl(emailUri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_contactEmail)),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteButton, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await AccountService.deleteAccount();

    if (result.success) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (result.needsReauth) {
      await _reauthenticateAndRetryDelete(l10n);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed), backgroundColor: Colors.red),
      );
    }
  }

  /// Firebase requires a *recent* login before it'll delete an account --
  /// see account_service.dart. This re-authenticates using whichever
  /// provider the person originally signed in with, then retries the
  /// deletion once, and surfaces a plain failure message if that also
  /// doesn't work (e.g. they cancel the picker, or a second reauth
  /// attempt is still somehow not "recent" enough).
  Future<void> _reauthenticateAndRetryDelete(AppLocalizations l10n) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final providerIds = user.providerData.map((p) => p.providerId).toSet();

    AuthCredential? credential;

    if (providerIds.contains('password')) {
      final password = await _promptForPassword(l10n);
      if (password == null || !mounted) return; // cancelled
      credential = EmailAuthProvider.credential(email: user.email!, password: password);
    } else if (providerIds.contains('google.com')) {
      credential = await SocialAuthService.getGoogleCredential();
    }
    // Anonymous/guest accounts have no provider to reauthenticate with --
    // deleteAccount() above should already have succeeded directly for
    // them without ever reaching this method.

    if (credential == null) return; // person cancelled the reauth step
    if (!mounted) return;

    final result = await AccountService.reauthenticateAndDelete(credential);
    if (result.success) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _promptForPassword(AppLocalizations l10n) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reauthRequiredTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reauthRequiredBody),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.passwordHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    return (password == null || password.isEmpty) ? null : password;
  }

  void _showLanguagePicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.languageSwitcherTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: !localeController.isArabic ? const Icon(Icons.check, color: AppColors.primaryTeal) : null,
                onTap: () {
                  Navigator.pop(context);
                  localeController.setLocale(LocaleController.english);
                  AnalyticsService.logLanguageChanged('en');
                },
              ),
              ListTile(
                title: Text(l10n.languageArabic),
                trailing: localeController.isArabic ? const Icon(Icons.check, color: AppColors.primaryTeal) : null,
                onTap: () {
                  Navigator.pop(context);
                  localeController.setLocale(LocaleController.egyptianArabic);
                  AnalyticsService.logLanguageChanged('ar');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondary, letterSpacing: 0.6),
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    // The background color lives on the inner Material, not this
    // Container's decoration -- ListTile paints its background/ink
    // splashes on the nearest Material ancestor, and an opaque
    // DecoratedBox between ListTile and that Material hides those
    // effects entirely (a well-known Flutter framework assertion).
    // The outer Container exists only for the margin and the custom
    // drop-shadow, which Material's own elevation doesn't replicate.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.onGoHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: widget.onGoHome,
              )
            : null,
        title: Text(l10n.settingsTitle, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          _sectionLabel(l10n.accountSectionLabel, context),
          _card(context, children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                child: Icon(user?.isAnonymous == true ? Icons.person_outline : Icons.person, color: AppColors.primaryTeal),
              ),
              title: Text(
                user?.isAnonymous == true
                    ? l10n.guestLabel
                    : ((user?.displayName != null && user!.displayName!.trim().isNotEmpty)
                        ? user.displayName!.trim()
                        : (user?.email ?? '—')),
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: (user != null &&
                      !user.isAnonymous &&
                      user.displayName != null &&
                      user.displayName!.trim().isNotEmpty &&
                      user.email != null)
                  ? Text(
                      user.email!,
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    )
                  : null,
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(l10n.logOut, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                await AccountService.clearUserDataOnSignOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(l10n.deleteAccountButton, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () => _confirmAndDeleteAccount(l10n),
            ),
          ]),

          _sectionLabel(l10n.preferencesSectionLabel, context),
          _card(context, children: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeController,
              builder: (context, mode, _) {
                // Resolve "system" against the current platform brightness so
                // the switch shows the right state even before the user has
                // ever overridden it.
                final isDarkNow = mode == ThemeMode.dark ||
                    (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                return SwitchListTile(
                  activeThumbColor: AppColors.primaryTeal,
                  secondary: Icon(Icons.dark_mode_outlined, color: context.textSecondary),
                  title: Text(l10n.darkModeLabel, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.darkModeSubtitle, style: TextStyle(color: context.textSecondary, fontSize: 12)),
                  value: isDarkNow,
                  onChanged: (val) {
                    themeController.setDarkMode(val);
                    AnalyticsService.logDarkModeToggled(val);
                  },
                );
              },
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: Icon(Icons.language, color: context.textSecondary),
              title: Text(l10n.languageSwitcherTitle, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
              trailing: Text(
                localeController.isArabic ? l10n.languageArabic : l10n.languageEnglish,
                style: TextStyle(color: context.textSecondary),
              ),
              onTap: () => _showLanguagePicker(l10n),
            ),
          ]),

          _sectionLabel(l10n.supportSectionLabel, context),
          _card(context, children: [
            ListTile(
              leading: const Icon(Icons.mail_outline, color: AppColors.primaryTeal),
              title: Text(l10n.contactUsLabel, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(_contactEmail, style: TextStyle(color: context.textSecondary, fontSize: 12)),
              trailing: Icon(Icons.open_in_new, size: 18, color: context.textSecondary),
              onTap: () => _launchContactEmail(l10n),
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: const Icon(Icons.star_outline_rounded, color: AppColors.primaryTeal),
              title: Text(l10n.rateGuidyLabel, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => ReviewService.openStoreListing(),
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryTeal),
              title: Text(l10n.privacyPolicyLabel, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.open_in_new, size: 18, color: context.textSecondary),
              // Served by Firebase Hosting on this project's own domain,
              // generated from the markdown sources by build_site.py. If a
              // custom domain is ever added, point this at that instead --
              // the .web.app URL keeps working either way.
              //
              // Follows the app's language rather than the phone's: someone
              // reading Guidy in Arabic should not be handed an English
              // legal document, and Localizations.localeOf reflects the
              // in-app language picker, not the system locale.
              onTap: () => launchUrl(
                Uri.parse(Localizations.localeOf(context).languageCode == 'ar'
                    ? 'https://guidy-19e46.web.app/privacy-ar'
                    : 'https://guidy-19e46.web.app/privacy'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Divider(height: 1, color: context.isDark ? Colors.white12 : Colors.black12),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.primaryTeal),
              // No l10n key for this one -- flutter gen-l10n isn't runnable
              // from this environment, and hand-editing the generated
              // app_localizations*.dart files has bitten this repo before
              // (see build_site.py's header). Same locale-conditional
              // pattern used all over the rest of the app (e.g.
              // LinesScreen._currentLangCode) instead of a generated getter.
              title: Text(
                Localizations.localeOf(context).languageCode == 'ar' ? 'الشروط والأحكام' : 'Terms and Conditions',
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(Icons.open_in_new, size: 18, color: context.textSecondary),
              onTap: () => launchUrl(
                Uri.parse(Localizations.localeOf(context).languageCode == 'ar'
                    ? 'https://guidy-19e46.web.app/terms-ar'
                    : 'https://guidy-19e46.web.app/terms'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Image.asset(
              context.isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
              height: 40,
              semanticLabel: 'Guidy Logo',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('v1.0.0', style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
