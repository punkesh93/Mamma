import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/user_model.dart';
import '../../models/health_metrics_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-c578e6c9-8cd4-4412-bd62-c325f63dac05',
  );

  // ── User Data ────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<UserModel?> getUser(String uid) async {
    final docSnap = await _db.collection('users').doc(uid).get();
    if (docSnap.exists && docSnap.data() != null) {
      return UserModel.fromJson(docSnap.data()!);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserModel.fromJson(snap.data()!);
      }
      return null;
    });
  }

  // ── Maternal Health Tracker (NEW) ────────────────────────────────────────

  Future<void> saveHealthRecord(HealthRecord record) async {
    // Write to users/{uid}/health_records/{id}
    final colRef = _db.collection('users').doc(record.userId).collection('health_records');
    if (record.id != null) {
      await colRef.doc(record.id).set(record.toJson());
    } else {
      await colRef.add(record.toJson());
    }
  }

  Future<void> deleteHealthRecord(String userId, String recordId) async {
    await _db.collection('users').doc(userId).collection('health_records').doc(recordId).delete();
  }

  Stream<List<HealthRecord>> streamHealthRecords(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('health_records')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HealthRecord.fromJson(doc.data(), doc.id)).toList();
    });
  }

  // ── AI Analyses (NEW) ───────────────────────────────────────────────────
  
  Future<void> saveAiAnalysis(String userId, String type, String prompt, String response) async {
    await _db.collection('users').doc(userId).collection('ai_analyses').add({
      'type': type,
      'prompt': prompt,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ── Doctor Reports (NEW) ────────────────────────────────────────────────
  
  Future<void> saveDoctorReport(String userId, Map<String, dynamic> reportData) async {
    await _db.collection('users').doc(userId).collection('doctor_reports').doc(reportData['id']).set(reportData);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDoctorReports(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('doctor_reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
