import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/screens/support/support_ticket_detail_screen.dart';
import 'package:marketplace/services/support_ticket_service.dart';

class CreateSupportTicketScreen extends StatefulWidget {
  final String userType;

  const CreateSupportTicketScreen({super.key, required this.userType});

  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _category = 'account';
  String _priority = 'medium';
  bool _isSubmitting = false;

  static const _categories = [
    'verification',
    'payment',
    'account',
    'listing',
    'dispute',
    'other',
  ];

  static const _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a ticket.')),
      );
      return;
    }

    final userName = (user.displayName?.trim().isNotEmpty == true)
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty == true
              ? user.email!.trim()
              : 'Marketplace user');
    final userEmail = user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : userName;

    setState(() => _isSubmitting = true);

    try {
      final ticketId = await SupportTicketService.createTicket(
        userId: user.uid,
        userEmail: userEmail,
        userName: userName,
        userType: widget.userType,
        subject: _subjectController.text.trim(),
        category: _category,
        priority: _priority,
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SupportTicketDetailScreen(
            ticketId: ticketId,
            userType: widget.userType,
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket created successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create support ticket: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Support Ticket')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Send a request to the support team for ${widget.userType == 'farmer' ? 'farmer' : 'buyer'} help.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category[0].toUpperCase() + category.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(
                            priority[0].toUpperCase() + priority.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Describe the issue you need help with';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit ticket'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
