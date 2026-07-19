import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/Auth/login.dart';
import 'package:marketplace/screens/chat/chat_screen.dart';
import 'package:marketplace/user_service.dart';
import 'package:marketplace/screens_buyer/orders.dart';
import 'package:marketplace/screens_buyer/favorite_farmers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildMenuTile(
              context,
              icon: Icons.favorite_border,
              title: 'Favorite Farmers',
              subtitle: 'View farmers you follow',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteFarmersScreen()),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              subtitle: 'View your purchase history',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'View updates and alerts',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Ask questions or report issues',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.security_outlined,
              title: 'Security',
              subtitle: 'Manage password and access',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              subtitle: 'Update name, email, phone and location',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.forum_outlined,
              title: 'Messages',
              subtitle: 'Continue chats with farmers',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final displayName = (data['displayName'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (displayName != null && displayName.isNotEmpty)
                          ? displayName
                          : (user?.displayName ?? 'Buyer'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (email != null && email.isNotEmpty)
                          ? email
                          : (user?.email ?? 'No email available'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buyer account',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.deepPurple.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationItem(
            title: 'New offer from local farmer',
            subtitle: 'Fresh produce available near you',
          ),
          _NotificationItem(
            title: 'Order update',
            subtitle: 'Your last purchase is out for delivery',
          ),
          _NotificationItem(
            title: 'System alert',
            subtitle: 'Maintenance scheduled at 11:00 PM tonight',
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        leading: const Icon(Icons.notifications_active_outlined),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact our support team for order help, delivery questions, and app issues.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _SupportCard(
              icon: Icons.chat_bubble_outline,
              title: 'Live chat',
              subtitle: 'Speak with support instantly',
            ),
            _SupportCard(
              icon: Icons.email_outlined,
              title: 'Email support',
              subtitle: 'support@shop-smartfarmer.com',
            ),
            _SupportCard(
              icon: Icons.phone_outlined,
              title: 'Call support',
              subtitle: '+254 700 000 000',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Protect your account with a strong password and secure access.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric login'),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Two-factor authentication'),
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _orderDetailsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _orderDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final profile = await UserService.getUserProfile(user.uid);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? <String, dynamic>{};

    if (!mounted) return;
    setState(() {
      _nameController.text = profile?.displayName ?? user.displayName ?? '';
      _emailController.text = profile?.email ?? user.email ?? '';
      _phoneController.text = profile?.phoneNumber ?? user.phoneNumber ?? '';
      _locationController.text = data['location'] as String? ?? '';
      _orderDetailsController.text = data['orderDetails'] as String? ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _orderDetailsController,
                      label: 'Order preferences',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();

      await UserService.updateUserProfile(user.uid, {
        'displayName': newName,
        'email': newEmail,
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'orderDetails': _orderDetailsController.text.trim(),
        'role': 'buyer',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (user.displayName != newName) {
        try {
          await user.updateDisplayName(newName);
        } catch (_) {}
      }

      if (user.email != newEmail) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
        } catch (_) {
          // Firestore remains the source of truth for the profile tab.
        }
      }

      try {
        await user.reload();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
