import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/scheduled_call.dart';

part 'scheduled_calls_providers.g.dart';

@riverpod
Future<List<ScheduledCall>> scheduledCalls(
  ScheduledCallsRef ref,
  String uid,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('scheduled_calls')
      .get();

  final now = DateTime.now();

  final calls = snapshot.docs
      .map((doc) => ScheduledCall.fromFirestore(doc.data()))
      .where((call) {
        try {
          return DateTime.parse(call.endTime).isAfter(now);
        } catch (e) {
          debugPrint('scheduledCalls: could not parse endTime for call — $e');
          return false;
        }
      })
      .toList()
    ..sort((a, b) {
      try {
        return DateTime.parse(a.endTime).compareTo(DateTime.parse(b.endTime));
      } catch (_) {
        return 0;
      }
    });

  return calls;
}
