import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/screens/support/create_support_ticket_screen.dart';
import 'package:marketplace/screens/support/support_ticket_detail_screen.dart';
import 'package:marketplace/services/support_ticket_service.dart';

class SupportTicketsScreen extends StatelessWidget {
  final String userType;

  const SupportTicketsScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your support tickets.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Support Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateSupportTicketScreen(userType: userType),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: SupportTicketService.streamTicketsForUser(
          user.uid,
        ).map((tickets) => tickets.cast<dynamic>()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load support tickets.'));
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You have no support tickets yet. Use New ticket to contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index].data() as Map<String, dynamic>;
              final ticketId = tickets[index].id as String;
              final ref = ticket['ref'] as String? ?? 'Ticket';
              final subject = ticket['subject'] as String? ?? '';
              final status = ticket['status'] as String? ?? 'open';
              final messages = ticket['messages'] as List<dynamic>? ?? const [];
              final lastMessage = messages.isEmpty
                  ? 'No messages yet'
                  : (messages.last as Map<String, dynamic>)['text']
                            as String? ??
                        'No messages yet';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    ref,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('$subject\n$lastMessage'),
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: status == 'closed'
                          ? Colors.grey
                          : Colors.green.shade700,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportTicketDetailScreen(
                          ticketId: ticketId,
                          userType: userType,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
