import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/user_service.dart';

class FarmerEditProfileScreen extends StatefulWidget {
  const FarmerEditProfileScreen({super.key});

  @override
  State<FarmerEditProfileScreen> createState() =>
      _FarmerEditProfileScreenState();
}

class _FarmerEditProfileScreenState extends State<FarmerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();
  final _bioController = TextEditingController();

  final _imagePicker = ImagePicker();
  XFile? _avatarFile;
  String? _existingPhotoUrl;

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
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _specialtiesController.dispose();
    _deliveryRadiusController.dispose();
    _bioController.dispose();
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
      _farmNameController.text = data['farmName'] as String? ?? '';
      _farmLocationController.text = data['farmLocation'] as String? ?? '';
      _specialtiesController.text = data['specialties'] as String? ?? '';
      final deliveryRadius = data['deliveryRadiusKm'];
      _deliveryRadiusController.text = deliveryRadius == null
          ? ''
          : deliveryRadius.toString();
      _bioController.text = data['bio'] as String? ?? '';
      _existingPhotoUrl =
          (data['photoURL'] as String?)?.trim().isNotEmpty == true
          ? data['photoURL'] as String?
          : (user.photoURL?.trim().isNotEmpty == true ? user.photoURL : null);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarPicker(),
                    const SizedBox(height: 20),
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
                    ),
                    _buildTextField(
                      controller: _farmNameController,
                      label: 'Farm name',
                      icon: Icons.agriculture_outlined,
                    ),
                    _buildTextField(
                      controller: _farmLocationController,
                      label: 'Farm location',
                      icon: Icons.location_on_outlined,
                    ),
                    _buildTextField(
                      controller: _specialtiesController,
                      label: 'Specialties',
                      icon: Icons.grass_outlined,
                      hintText: 'Tomatoes, maize, dairy',
                    ),
                    _buildTextField(
                      controller: _deliveryRadiusController,
                      label: 'Delivery radius (km)',
                      icon: Icons.route_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _buildTextField(
                      controller: _bioController,
                      label: 'About your farm',
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

  Widget _buildAvatarPicker() {
    final hasSelectedImage = _avatarFile != null;
    ImageProvider? imageProvider;
    if (hasSelectedImage) {
      imageProvider = FileImage(File(_avatarFile!.path));
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingPhotoUrl!);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.green.shade50,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.camera_alt_outlined,
                    size: 34,
                    color: Colors.green.shade700,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _pickAvatar,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Change avatar'),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    if (!mounted) return;
    setState(() => _avatarFile = file);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
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
          hintText: hintText,
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
      final displayName = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final farmLocation = _farmLocationController.text.trim();
      final specialtiesText = _specialtiesController.text.trim();
      final crops = specialtiesText
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      final deliveryRadius = double.tryParse(
        _deliveryRadiusController.text.trim(),
      );

      final updates = <String, dynamic>{
        'name': displayName,
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'phoneNumber': phone,
        'location': farmLocation,
        'farmName': _farmNameController.text.trim(),
        'farmLocation': farmLocation,
        'specialties': specialtiesText,
        'crops': crops,
        'deliveryRadiusKm': deliveryRadius,
        'bio': _bioController.text.trim(),
        'role': 'farmer',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (_avatarFile != null) {
        final avatarUrl = await MarketService.uploadMediaFile(_avatarFile!);
        updates['photoURL'] = avatarUrl;
      }

      await UserService.updateUserProfile(user.uid, updates);

      if (_avatarFile != null) {
        try {
          await user.updatePhotoURL(updates['photoURL'] as String?);
        } catch (_) {}
      }

      if (user.displayName != displayName) {
        try {
          await user.updateDisplayName(displayName);
        } catch (_) {}
      }

      if (user.email != email) {
        try {
          await user.verifyBeforeUpdateEmail(email);
        } catch (_) {}
      }

      try {
        await user.reload();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
