import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketService {
  static final _ticketsRef = FirebaseFirestore.instance.collection('tickets');

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamTicketsForUser(String userId) {
    return _ticketsRef
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamTicket(
    String ticketId,
  ) {
    return _ticketsRef.doc(ticketId).snapshots();
  }

  static Future<String> createTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required String userType,
    required String subject,
    required String category,
    required String priority,
    required String message,
  }) async {
    final now = DateTime.now().toIso8601String();
    final ticketDoc = _ticketsRef.doc();
    final ticketRef = '#TKT-${ticketDoc.id.substring(0, 8).toUpperCase()}';

    await ticketDoc.set({
      'ref': ticketRef,
      'subject': subject,
      'user': userName,
      'userEmail': userEmail,
      'userId': userId,
      'userType': userType,
      'userAvatarColor': userType == 'farmer'
          ? 'bg-emerald-600'
          : 'bg-indigo-600',
      'category': category,
      'status': 'open',
      'priority': priority,
      'createdAt': now,
      'updatedAt': now,
      'assignedTo': null,
      'messages': [
        {
          'id': 'msg_${ticketDoc.id}',
          'sender': 'user',
          'author': userName,
          'authorType': 'user',
          'text': message,
          'createdAt': now,
        },
      ],
      'internalNotes': <Map<String, dynamic>>[],
    });

    return ticketDoc.id;
  }

  static Future<void> replyToTicket({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final ticketRef = _ticketsRef.doc(ticketId);
    final now = DateTime.now().toIso8601String();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketRef);
      if (!snapshot.exists) {
        throw StateError('Ticket not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final messages = List<Map<String, dynamic>>.from(
        (data['messages'] as List<dynamic>? ?? const []).map(
          (entry) => Map<String, dynamic>.from(entry as Map),
        ),
      );

      messages.add({
        'id': 'msg_$ticketId-${messages.length + 1}',
        'sender': senderType,
        'author': senderName,
        'authorType': senderType,
        'senderId': senderId,
        'text': trimmed,
        'createdAt': now,
      });

      transaction.set(ticketRef, {
        'messages': messages,
        'updatedAt': now,
        'status': data['status'] == 'closed' ? 'open' : data['status'],
      }, SetOptions(merge: true));
    });
  }
}
