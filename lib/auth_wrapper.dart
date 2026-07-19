import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/Auth/login.dart';
import 'package:marketplace/Homepage/homepage.dart';
import 'package:marketplace/Homepage/homepage_buyer.dart';
import 'package:marketplace/models/user_profile.dart' as user_profile;
import 'package:marketplace/role_selection_screen.dart';
import 'package:marketplace/services/user_session.dart' as user_session;
import 'package:marketplace/user_service.dart';
import 'package:marketplace/theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (authSnapshot.hasError) {
          return _ErrorScreen(error: authSnapshot.error.toString());
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<user_profile.UserRole?>(
          future: UserService.resolveUserRole(user),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (roleSnapshot.hasError) {
              return _ErrorScreen(error: roleSnapshot.error.toString());
            }

            final role = roleSnapshot.data;
            if (role == null) {
              return RoleSelectionScreen(user: user);
            }

            user_session.UserSession.setRole(
              role,
            ); // Set the role in the UserSession
            return role == user_profile.UserRole.farmer
                ? const HomePage()
                : const HomePageBuyer();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication error'),
        backgroundColor: AppTheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              'Unable to load your account.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
