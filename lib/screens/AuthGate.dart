import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MainNavigator.dart';
import 'SignInScreen.dart';
import '../theme/app_theme.dart';

import '../services/saved_trips_service.dart';
import '../services/saved_places_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      // Graceful fallback if Firebase is uninitialized (e.g. desktop preview or offline tests)
      return const MainNavigator();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading spinner while Firebase checks the user's token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.surfaceCard,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
          );
        }
        
        // If the user is successfully logged in, take them to the main app layout
        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null && !user.isAnonymous) {
            SavedTripsService.syncWithCloud(user);
            SavedPlacesService.syncWithCloud(user);
          }
          return const MainNavigator(); 
        }
        
        // Otherwise, send them to the login screen
        return const SignInScreen();
      },
    );
  }
}