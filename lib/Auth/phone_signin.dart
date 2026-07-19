import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marketplace/Homepage/homepage.dart';
import 'package:marketplace/Homepage/homepage_buyer.dart';
import 'package:marketplace/models/user_profile.dart';
import 'package:marketplace/role_selection_screen.dart';
import 'package:marketplace/services/user_session.dart' as user_session;
import 'package:marketplace/theme.dart';
import 'package:marketplace/user_service.dart';

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  State<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String _selectedCountryCode = '+233';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _goToRoleBasedHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final role = await UserService.resolveUserRole(user);
    if (!mounted) return;
    if (role == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleSelectionScreen(user: user)),
      );
      return;
    }

    user_session.UserSession.setRole(role);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            role == UserRole.farmer ? const HomePage() : const HomePageBuyer(),
      ),
    );
  }

  void _verifyPhone() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) return;
    final phone = '$_selectedCountryCode$number';
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _goToRoleBasedHome();
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone verification failed: ${e.message}')),
        );
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _codeSent = true;
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  void _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _goToRoleBasedHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.38).clamp(260.0, 300.0).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroSection(heroHeight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter your phone number',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add your number to continue browsing products, messaging sellers, and closing deals securely.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.black54,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCountryCode,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                    items: _countryCodes.map((country) {
                                      return DropdownMenuItem<String>(
                                        value: country['code'],
                                        child: Text(
                                          '${country['flag'] ?? ''} ${country['code'] ?? ''}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedCountryCode = value,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      hintText: 'Phone number',
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyPhone,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Continue'),
                              ),
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 20),
                              TextField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Verification code',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Verify code'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Terms'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Privacy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(double height) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.authGradient()),
        child: Stack(
          children: [
            Positioned(top: 16, left: 20, child: _buildBrandBadge()),
            Positioned(top: 16, right: 20, child: _buildGlowDot(44)),
            Positioned(bottom: 64, left: 20, child: _buildGlowDot(28)),
            const Positioned(
              left: 20,
              right: 28,
              top: 76,
              child: Text(
                'Buy, sell and discover locally',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  height: 1.18,
                ),
              ),
            ),
            const Positioned(
              left: 20,
              right: 28,
              top: 148,
              child: Text(
                'Sign in to access trusted sellers, offers, and seamless commerce experiences.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: _buildMarketplaceIllustration(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Icon(Icons.storefront_outlined, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Marketplace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
      ),
    );
  }

  Widget _buildMarketplaceIllustration() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Positioned(
            left: 74,
            top: 14,
            child: Container(
              width: 96,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fresh find',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Local deals',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 14,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
