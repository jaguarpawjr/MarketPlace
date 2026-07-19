import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/Homepage/homepage.dart';
import 'package:marketplace/Homepage/homepage_buyer.dart';
import 'package:marketplace/models/user_profile.dart' as user_profile;
import 'package:marketplace/services/user_session.dart'  as user_session;
import 'package:marketplace/user_service.dart';
import 'package:marketplace/theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final User user;

  const RoleSelectionScreen({super.key, required this.user});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int? _selectedRoleIndex;
  bool _isSaving = false;
  String? _errorMessage;

  static const _roleOptions = [
    _RoleOption(
      role: user_profile.UserRole.farmer,
      title: 'Farmer',
      subtitle: 'Sell agricultural products, manage listings, and access farm tools.',
      icon: Icons.agriculture_outlined,
    ),
    _RoleOption(
      role: user_profile.UserRole.buyer,
      title: 'Buyer',
      subtitle: 'Browse products, contact farmers, and track orders.',
      icon: Icons.shopping_basket_outlined,
    ),
  ];

  void _onContinue() async {
    final selectedIndex = _selectedRoleIndex;
    if (selectedIndex == null) return;

    final selectedRole = _roleOptions[selectedIndex].role;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await UserService.saveUserProfile(widget.user, selectedRole);
      user_session.UserSession.currentRole = selectedRole;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => selectedRole == user_profile.UserRole.farmer
              ? const HomePage()
              : const HomePageBuyer(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Welcome to Marketplace'),
        backgroundColor: AppTheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How would you like to use the app?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a role to personalize your Marketplace experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _roleOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final option = _roleOptions[index];
                    final selected = index == _selectedRoleIndex;
                    return _RoleCard(
                      option: option,
                      selected: selected,
                      onTap: () => setState(() => _selectedRoleIndex = index),
                    );
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRoleIndex == null || _isSaving ? null : _onContinue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final user_profile.UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary   : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(option.icon, color: AppTheme.primary, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppTheme.primary : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                option.subtitle,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
