import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/routine_step.dart';

class RoutineCloudStorage {
  const RoutineCloudStorage();

  Future<User?> _user() async {
    if (Firebase.apps.isEmpty) return null;
    final auth = FirebaseAuth.instance;
    return auth.currentUser ?? (await auth.signInAnonymously()).user;
  }

  Future<List<RoutineStep>?> loadSteps(RoutinePeriod period) async {
    final user = await _user();
    if (user == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .doc('users/${user.uid}/routines/${period.name}')
        .get();
    final data = snapshot.data();
    final tasks = data?['tasks'];
    if (tasks is! List) return null;
    return tasks
        .whereType<Map>()
        .map((task) => RoutineStep.fromJson(Map<String, dynamic>.from(task)))
        .toList();
  }

  Future<void> saveSteps(RoutinePeriod period, List<RoutineStep> steps) async {
    final user = await _user();
    if (user == null) return;
    await FirebaseFirestore.instance
        .doc('users/${user.uid}/routines/${period.name}')
        .set({
          'period': period.name,
          'tasks': steps.map((step) => step.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<RoutineDayRecord>> loadHistory() async {
    final user = await _user();
    if (user == null) return <RoutineDayRecord>[];
    final snapshot = await FirebaseFirestore.instance
        .collection('users/${user.uid}/routineHistory')
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((document) => RoutineDayRecord.fromJson(document.data()))
        .toList();
  }

  Future<void> saveDay(RoutineDayRecord record) async {
    final user = await _user();
    if (user == null) return;
    await FirebaseFirestore.instance
        .doc('users/${user.uid}/routineHistory/${record.date}')
        .set({...record.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
  }
}
