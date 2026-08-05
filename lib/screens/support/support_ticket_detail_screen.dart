import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/services/support_ticket_service.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final String userType;

  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.userType,
  });

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Support ticket')),
      body: currentUser == null
          ? const Center(child: Text('Sign in to view tickets.'))
          : StreamBuilder(
              stream: SupportTicketService.streamTicket(widget.ticketId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ticket = snapshot.data?.data();
                if (ticket == null) {
                  return const Center(child: Text('Ticket not found.'));
                }

                final messages = List<Map<String, dynamic>>.from(
                  (ticket['messages'] as List<dynamic>? ?? const []).map(
                    (entry) => Map<String, dynamic>.from(entry as Map),
                  ),
                );

                return Column(
                  children: [
                    _buildHeader(ticket),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final senderType =
                              (message['authorType'] as String?) ?? 'support';
                          final isMine =
                              message['senderId'] == currentUser.uid ||
                              senderType == 'user';
                          return _MessageBubble(
                            author: (message['author'] as String?) ?? 'Support',
                            text: (message['text'] as String?) ?? '',
                            createdAt: message['createdAt'] as String?,
                            isMine: isMine,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Write a reply...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton(
                              heroTag: null,
                              mini: true,
                              onPressed: _sending
                                  ? null
                                  : () => _reply(currentUser.uid, currentUser),
                              child: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> ticket) {
    final ref = ticket['ref'] as String? ?? 'Support ticket';
    final subject = ticket['subject'] as String? ?? '';
    final status = ticket['status'] as String? ?? 'open';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subject,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Status: ${status[0].toUpperCase()}${status.substring(1)}'),
        ],
      ),
    );
  }

  Future<void> _reply(String currentUserId, User currentUser) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await SupportTicketService.replyToTicket(
        ticketId: widget.ticketId,
        senderId: currentUserId,
        senderName:
            currentUser.displayName ?? currentUser.email ?? 'Marketplace user',
        senderType: 'user',
        message: text,
      );
      _replyController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send reply: $error')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String author;
  final String text;
  final String? createdAt;
  final bool isMine;

  const _MessageBubble({
    required this.author,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isMine ? Colors.green.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: TextStyle(
                color: isMine ? Colors.white70 : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
