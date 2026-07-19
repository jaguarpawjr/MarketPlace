
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

DateTime _parseCreatedAt(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}

class FarmConversationEntry {
  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  FarmConversationEntry({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FarmConversationEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmConversationEntry(
      id: doc.id,
      role: data['role'] as String? ?? 'unknown',
      text: data['text'] as String? ?? '',
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }
}

class FarmDiagnosisRecord {
  final String id;
  final String cropType;
  final String location;
  final String imageUrl;
  final String summary;
  final DateTime createdAt;

  FarmDiagnosisRecord({
    required this.id,
    required this.cropType,
    required this.location,
    required this.imageUrl,
    required this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cropType': cropType,
      'location': location,
      'imageUrl': imageUrl,
      'summary': summary,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FarmDiagnosisRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmDiagnosisRecord(
      id: doc.id,
      cropType: data['cropType'] as String? ?? 'Unknown',
      location: data['location'] as String? ?? 'Unknown',
      imageUrl: data['imageUrl'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }
}

class FarmNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  FarmNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FarmNote.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmNote(
      id: doc.id,
      title: data['title'] as String? ?? 'Quick note',
      content: data['content'] as String? ?? '',
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }
}

class FarmReminder {
  final String id;
  final String title;
  final String details;
  final DateTime dueDate;
  final bool completed;

  FarmReminder({
    required this.id,
    required this.title,
    required this.details,
    required this.dueDate,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'details': details,
      'dueDate': Timestamp.fromDate(dueDate),
      'completed': completed,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory FarmReminder.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmReminder(
      id: doc.id,
      title: data['title'] as String? ?? 'Reminder',
      details: data['details'] as String? ?? '',
      dueDate: _parseCreatedAt(data['dueDate']),
      completed: data['completed'] as bool? ?? false,
    );
  }
}

class FarmEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final Duration duration;

  FarmEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'durationMinutes': duration.inMinutes,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory FarmEvent.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmEvent(
      id: doc.id,
      title: data['title'] as String? ?? 'Calendar event',
      description: data['description'] as String? ?? '',
      startDate: _parseCreatedAt(data['startDate']),
      duration: Duration(minutes: (data['durationMinutes'] as int?) ?? 60),
    );
  }
}

class FarmTimerEntry {
  final String id;
  final String label;
  final Duration duration;
  final DateTime startTime;

  FarmTimerEntry({
    required this.id,
    required this.label,
    required this.duration,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'durationMinutes': duration.inMinutes,
      'startTime': Timestamp.fromDate(startTime),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory FarmTimerEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmTimerEntry(
      id: doc.id,
      label: data['label'] as String? ?? 'Timer',
      duration: Duration(minutes: (data['durationMinutes'] as int?) ?? 0),
      startTime: _parseCreatedAt(data['startTime']),
    );
  }
}

class FarmMemoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _farmerId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User must be signed in to use Farm tools.');
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> _farmerDoc(String farmerId) {
    return _db.collection('farmers').doc(farmerId);
  }

  static Future<String> uploadImage(XFile image, {String? farmerId}) async {
    final ownerId = farmerId ?? _farmerId();
    
    final safeName = image.name.replaceAll(' ', '_');
    final storagePath =
        'farm_diagnosis_images/$ownerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref().child(storagePath);

    try {
      final metadata = SettableMetadata(
        contentType: image.mimeType,
      );
      final uploadTask = ref.putData(await image.readAsBytes(), metadata);
      await uploadTask.whenComplete(() {});
      final downloadUrl = await ref.getDownloadURL();

      await _farmerDoc(ownerId).collection('farm_diagnosis_images').add({
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'fileName': safeName,
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message:
            'Firebase Storage upload failed for $storagePath: ${e.message}',
      );
    }
  }

  static Future<void> saveConversation(
    String farmerId,
    String role,
    String text,
  ) async {
    final collection = _farmerDoc(farmerId).collection('conversations');
    await collection.add({
      'role': role,
      'text': text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmConversationEntry>> fetchRecentConversations(
    String farmerId, {
    int limit = 8,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('conversations')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => FarmConversationEntry.fromDocument(doc))
        .toList();
  }

  static Future<void> saveDiagnosis(
    String farmerId, {
    required String cropType,
    required String location,
    required String imageUrl,
    required String summary,
  }) async {
    final collection = _farmerDoc(farmerId).collection('diagnoses');
    await collection.add({
      'cropType': cropType,
      'location': location,
      'imageUrl': imageUrl,
      'summary': summary,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmDiagnosisRecord>> fetchRecentDiagnoses(
    String farmerId, {
    int limit = 5,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('diagnoses')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => FarmDiagnosisRecord.fromDocument(doc))
        .toList();
  }

  static Future<void> saveNote(
    String farmerId, {
    required String title,
    required String content,
  }) async {
    final collection = _farmerDoc(farmerId).collection('notes');
    await collection.add({
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmNote>> fetchRecentNotes(
    String farmerId, {
    int limit = 5,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => FarmNote.fromDocument(doc)).toList();
  }

  static Future<void> createReminder(
    String farmerId, {
    required String title,
    required String details,
    required DateTime dueDate,
  }) async {
    final collection = _farmerDoc(farmerId).collection('reminders');
    await collection.add({
      'title': title,
      'details': details,
      'dueDate': Timestamp.fromDate(dueDate),
      'completed': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmReminder>> fetchReminders(
    String farmerId, {
    int limit = 10,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('reminders')
        .orderBy('dueDate', descending: false)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => FarmReminder.fromDocument(doc)).toList();
  }

  static Future<void> scheduleEvent(
    String farmerId, {
    required String title,
    required String description,
    required DateTime startDate,
    required Duration duration,
  }) async {
    final collection = _farmerDoc(farmerId).collection('calendar_events');
    await collection.add({
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'durationMinutes': duration.inMinutes,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmEvent>> fetchEvents(
    String farmerId, {
    int limit = 10,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('calendar_events')
        .orderBy('startDate', descending: false)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => FarmEvent.fromDocument(doc)).toList();
  }

  static Future<void> setTimer(
    String farmerId, {
    required String label,
    required Duration duration,
  }) async {
    final collection = _farmerDoc(farmerId).collection('timers');
    await collection.add({
      'label': label,
      'durationMinutes': duration.inMinutes,
      'startTime': Timestamp.fromDate(DateTime.now()),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<List<FarmTimerEntry>> fetchTimers(
    String farmerId, {
    int limit = 10,
  }) async {
    final snapshot = await _farmerDoc(farmerId)
        .collection('timers')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => FarmTimerEntry.fromDocument(doc))
        .toList();
  }

  static Future<String> buildMemorySummary(String farmerId) async {
    final notes = await fetchRecentNotes(farmerId, limit: 3);
    final diagnoses = await fetchRecentDiagnoses(farmerId, limit: 2);
    final lastConversations = await fetchRecentConversations(
      farmerId,
      limit: 4,
    );

    final buffer = StringBuffer();
    if (notes.isNotEmpty) {
      buffer.writeln('Previous farm notes:');
      for (final note in notes) {
        buffer.writeln('- ${note.title}: ${note.content}');
      }
      buffer.writeln();
    }

    if (diagnoses.isNotEmpty) {
      buffer.writeln('Recent diagnoses:');
      for (final diagnosis in diagnoses) {
        buffer.writeln(
          '- ${diagnosis.cropType} at ${diagnosis.location}: ${diagnosis.summary}',
        );
      }
      buffer.writeln();
    }

    if (lastConversations.isNotEmpty) {
      buffer.writeln('Recent conversation context:');
      for (final convo in lastConversations.reversed) {
        buffer.writeln('${convo.role}: ${convo.text}');
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}
