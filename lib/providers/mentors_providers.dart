import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/mentor.dart';

part 'mentors_providers.g.dart';

@riverpod
Future<List<Mentor>> mentors(Ref ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('mentors')
      .where('isHidden', isEqualTo: false)
      .get();
  return snapshot.docs
      .map((doc) => Mentor.fromMap(doc.id, doc.data()))
      .toList();
}

@riverpod
Future<Mentor?> mentorById(Ref ref, String mentorId) async {
  final doc = await FirebaseFirestore.instance
      .collection('mentors')
      .doc(mentorId)
      .get();
  if (!doc.exists) return null;
  return Mentor.fromMap(doc.id, doc.data()!);
}
