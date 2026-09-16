import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Result of an account-deletion attempt.
///
/// `needsReauth` is the important case: Firebase requires a *recent*
/// login before it'll delete an account (security measure -- otherwise a
/// stolen, still-logged-in device could delete someone's account with no
/// further proof of identity). If the person's session isn't recent
/// enough, deletion fails with FirebaseAuthException code
/// 'requires-recent-login', and the caller needs to re-authenticate (see
/// [AccountService.reauthenticateAndDelete]) before trying again.
class AccountDeletionResult {
  final bool success;
  final bool needsReauth;
  final String? error;

  const AccountDeletionResult({this.success = false, this.needsReauth = false, this.error});
}

class AccountService {
  /// Attempts to delete the signed-in user directly. This succeeds
  /// immediately for guest/anonymous accounts (nothing to re-challenge)
  /// and for any account whose login is still "recent" by Firebase's own
  /// definition. For anything else, check `result.needsReauth` and follow
  /// up with [reauthenticateAndDelete] using a fresh credential for
  /// whichever provider `user.providerData` reports.
  static Future<AccountDeletionResult> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AccountDeletionResult(error: 'not-signed-in');
    }
    try {
      await _cleanupUserData(user.uid);
      await user.delete();
      return const AccountDeletionResult(success: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AccountDeletionResult(needsReauth: true);
      }
      return AccountDeletionResult(error: e.message ?? e.code);
    } catch (e) {
      return AccountDeletionResult(error: e.toString());
    }
  }

  /// Re-authenticates with a freshly-obtained credential, then deletes.
  /// Call this after [deleteAccount] returns `needsReauth: true`.
  static Future<AccountDeletionResult> reauthenticateAndDelete(AuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AccountDeletionResult(error: 'not-signed-in');
    }
    try {
      await user.reauthenticateWithCredential(credential);
      await _cleanupUserData(user.uid);
      await user.delete();
      return const AccountDeletionResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AccountDeletionResult(error: e.message ?? e.code);
    } catch (e) {
      return AccountDeletionResult(error: e.toString());
    }
  }

  static Future<void> _cleanupUserData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(uid);

      final trips = await userDoc.collection('saved_trips').get();
      for (final doc in trips.docs) {
        await doc.reference.delete();
      }

      final places = await userDoc.collection('saved_places').get();
      for (final doc in places.docs) {
        await doc.reference.delete();
      }

      await userDoc.delete();
    } catch (_) {}
  }

  static const String prefKeyDisplayName = 'user_display_name';

  /// Safe accessor for the currently authenticated Firebase user.
  static User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the conversational first name from any full name string.
  /// E.g.:
  /// - "Youssef Ezzat" -> "Youssef"
  /// - "أحمد محمد" -> "أحمد"
  /// - "Sara" -> "Sara"
  static String? extractFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return null;
    final trimmed = fullName.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first;
    }
    return trimmed;
  }

  /// Saves the user's display name locally in SharedPreferences, and syncs to
  /// Firebase Auth and Firestore if a user is currently logged in.
  static Future<void> saveUserDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyDisplayName, trimmed);
    } catch (_) {}

    final user = currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await user.updateDisplayName(trimmed);
        await user.reload();
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Retrieves the user's display name.
  /// Precedence:
  /// 1. FirebaseAuth currentUser.displayName
  /// 2. SharedPreferences cached name
  /// 3. Firestore doc ('users/{uid}')
  static Future<String?> getUserDisplayName() async {
    final user = currentUser;
    if (user != null && !user.isAnonymous) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        final name = user.displayName!.trim();
        _cacheLocalDisplayName(name);
        return name;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(prefKeyDisplayName);
      if (cached != null && cached.trim().isNotEmpty) {
        return cached.trim();
      }
    } catch (_) {}

    if (user != null && !user.isAnonymous) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final name = data?['displayName'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            _cacheLocalDisplayName(name.trim());
            return name.trim();
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Retrieves the user's first name for greeting and friendly UI displays.
  static Future<String?> getUserFirstName() async {
    final fullName = await getUserDisplayName();
    return extractFirstName(fullName);
  }

  static void _cacheLocalDisplayName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyDisplayName, name);
    } catch (_) {}
  }

  /// Clears cached user profile data upon sign-out.
  static Future<void> clearUserDataOnSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKeyDisplayName);
    } catch (_) {}
  }

  /// Formats a time-of-day greeting contextualized with the user's name if available.
  /// - Morning (5:00 - 11:59): "Good morning, {name}" / "صباح الخير يا {name}"
  /// - Afternoon (12:00 - 16:59): "Good afternoon, {name}" / "نهارك سعيد يا {name}"
  /// - Evening (17:00 - 20:59): "Good evening, {name}" / "مساء الخير يا {name}"
  /// - Night (21:00 - 4:59): "Good night, {name}" / "سهرة سعيدة يا {name}"
  /// If [name] is null/empty, falls back to generic greetings.
  static String formatGreeting(AppLocalizations l10n, {String? name, int? hourOverride}) {
    final hour = hourOverride ?? DateTime.now().hour;
    final cleanName = extractFirstName(name);

    if (cleanName != null && cleanName.isNotEmpty) {
      if (hour >= 5 && hour < 12) return l10n.goodMorningUser(cleanName);
      if (hour >= 12 && hour < 17) return l10n.goodAfternoonUser(cleanName);
      if (hour >= 17 && hour < 21) return l10n.goodEveningUser(cleanName);
      return l10n.goodNightUser(cleanName);
    }

    if (hour >= 5 && hour < 12) return l10n.goodMorning;
    if (hour >= 12 && hour < 17) return l10n.goodAfternoon;
    if (hour >= 17 && hour < 21) return l10n.goodEvening;
    return l10n.goodNight;
  }
}
