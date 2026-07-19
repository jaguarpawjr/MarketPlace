import 'package:flutter/material.dart';
import 'package:marketplace/Auth/phone_signin.dart';
import 'package:marketplace/Homepage/homepage.dart';
import 'package:marketplace/Homepage/homepage_buyer.dart';
import 'package:marketplace/role_selection_screen.dart';
import 'package:marketplace/services/user_session.dart' as session;
import 'package:marketplace/theme.dart';
import 'package:marketplace/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // canceled
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _handlePostSignIn(userCredential.user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (loginResult.status != LoginStatus.success ||
          loginResult.accessToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      final credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _handlePostSignIn(userCredential.user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook sign-in failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _handlePostSignIn(User? user) async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final role = await UserService.resolveUserRole(user);
      if (!mounted) return;
      if (role == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RoleSelectionScreen(user: user)),
        );
      } else {
        // Set the role in session and navigate
        session.UserSession.setRole(role);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role.name == 'farmer'
                ? const HomePage()
                : const HomePageBuyer(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Padding(
            padding: EdgeInsets.only(top: height < 720 ? 8 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandHeader(),
                SizedBox(height: height < 720 ? 28 : 46),
                Text(
                  'Choose how to sign in',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use your phone number or continue with Google to access your marketplace account.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSignInOption(
                  icon: Icons.phone_iphone_rounded,
                  title: 'Continue with phone',
                  subtitle: 'Get a secure SMS code for quick access.',
                  accentColor: AppTheme.primary,
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PhoneSignInPage(),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 14),
                _buildSignInOption(
                  icon: Icons.g_mobiledata_rounded,
                  title: 'Continue with Google',
                  subtitle: 'Use the Google account already on your device.',
                  accentColor: const Color(0xFF4285F4),
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 14),
                _buildSignInOption(
                  icon: Icons.facebook,
                  title: 'Continue with Facebook',
                  subtitle: 'Sign in quickly using your Facebook account.',
                  accentColor: const Color(0xFF1877F2),
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _signInWithFacebook,
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'Secure sign-in for buyers and farmers',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your account keeps messages, listings, and orders connected across the app.',
                          style: TextStyle(color: Colors.black54, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.authGradient(),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.storefront_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketplace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Buy, sell, and discover locally',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: accentColor,
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: 24,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
