import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String buyerId;
  final String farmerId;
  final String buyerName;
  final String farmerName;
  final String? productId;
  final String? productName;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;

  const ChatConversation({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.buyerName,
    required this.farmerName,
    required this.lastMessage,
    required this.lastSenderId,
    this.productId,
    this.productName,
    this.updatedAt,
  });

  List<String> get participantIds => [buyerId, farmerId];

  String nameFor(String userId) => userId == buyerId ? farmerName : buyerName;

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'farmerId': farmerId,
      'buyerName': buyerName,
      'farmerName': farmerName,
      'productId': productId,
      'productName': productName,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'participantIds': participantIds,
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ChatConversation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatConversation(
      id: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? 'Buyer',
      farmerName: data['farmerName'] as String? ?? 'Farmer',
      productId: data['productId'] as String?,
      productName: data['productName'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderId: data['lastSenderId'] as String? ?? '',
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

class ConversationMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  const ConversationMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory ConversationMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ConversationMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      createdAt: ChatConversation._parseTimestamp(data['createdAt']),
    );
  }
}

class ChatService {
  static final _conversationsRef =
      FirebaseFirestore.instance.collection('conversations');

  static String conversationId({
    required String buyerId,
    required String farmerId,
  }) {
    return '${buyerId}_$farmerId';
  }

  static Future<ChatConversation> openConversation({
    required String buyerId,
    required String farmerId,
    required String buyerName,
    required String farmerName,
    String? productId,
    String? productName,
  }) async {
    final id = conversationId(buyerId: buyerId, farmerId: farmerId);
    final ref = _conversationsRef.doc(id);
    final existing = await ref.get();
    final now = DateTime.now();

    final conversation = ChatConversation(
      id: id,
      buyerId: buyerId,
      farmerId: farmerId,
      buyerName: buyerName,
      farmerName: farmerName,
      productId: productId ?? (existing.data()?['productId'] as String?),
      productName: productName ?? (existing.data()?['productName'] as String?),
      lastMessage: existing.data()?['lastMessage'] as String? ?? '',
      lastSenderId: existing.data()?['lastSenderId'] as String? ?? '',
      updatedAt: now,
    );

    final createdAt = existing.exists ? (existing.data()?['createdAt'] as Timestamp?)?.toDate() : now;

    await ref.set(
      {
        ...conversation.toMap(),
        'createdAt': createdAt,
      },
      SetOptions(merge: true),
    );

    return conversation;
  }

  static Stream<List<ChatConversation>> streamConversationsForUser(
    String userId,
  ) {
    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map(ChatConversation.fromDocument)
              .toList();
          conversations.sort((a, b) {
            final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return conversations;
        });
  }

  static Stream<List<ConversationMessage>> streamMessages(
    String conversationId,
  ) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(ConversationMessage.fromDocument)
            .toList());
  }

  static Future<void> sendMessage({
    required ChatConversation conversation,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationRef = _conversationsRef.doc(conversation.id);
    final messageRef = conversationRef.collection('messages').doc();
    final now = DateTime.now();

    await messageRef.set(
      ConversationMessage(
        id: messageRef.id,
        senderId: senderId,
        senderName: senderName,
        text: trimmed,
        createdAt: now,
      ).toMap(),
    );

    await conversationRef.set(
      {
        ...conversation.toMap(),
        'lastMessage': trimmed,
        'lastSenderId': senderId,
        'updatedAt': Timestamp.fromDate(now),
        'participantIds': conversation.participantIds,
      },
      SetOptions(merge: true),
    );
  }
}