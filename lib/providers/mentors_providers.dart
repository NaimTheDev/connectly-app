import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mentor.dart';

/// Public mentors list (readable by anyone)
final mentorsProvider = FutureProvider<List<Mentor>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('mentors')
      .where('isHidden', isEqualTo: false)
      .get();
  return snapshot.docs.map((doc) {
    final data = doc.data();
    return Mentor(
      id: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      expertise: data['expertise'] ?? '',
      imageUrl: data['imageUrl'],
      categories: (data['categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      firstName: data['firstName'],
      lastName: data['lastName'],
    );
  }).toList();
});

/// Provider for fetching a specific mentor by ID
final mentorByIdProvider = FutureProvider.family<Mentor?, String>((
  ref,
  mentorId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('mentors')
        .doc(mentorId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return Mentor.fromMap(doc.id, doc.data()!);
  } catch (e) {
    throw Exception('Failed to fetch mentor: $e');
  }
});
