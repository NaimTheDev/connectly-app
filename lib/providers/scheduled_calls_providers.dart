import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/scheduled_call.dart';

part 'scheduled_calls_providers.g.dart';

// Streams the user's scheduled calls so the UI updates live as the Calendly
// webhook writes/updates documents — no app restart required.
@riverpod
Stream<List<ScheduledCall>> scheduledCalls(
  Ref ref,
  String uid,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('scheduled_calls')
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();

        return snapshot.docs
            .map((doc) => ScheduledCall.fromFirestore(doc.data()))
            .where((call) {
              try {
                return DateTime.parse(call.endTime).isAfter(now);
              } catch (e) {
                debugPrint(
                  'scheduledCalls: could not parse endTime for call — $e',
                );
                return false;
              }
            })
            .toList()
          ..sort((a, b) {
            try {
              return DateTime.parse(
                a.endTime,
              ).compareTo(DateTime.parse(b.endTime));
            } catch (_) {
              return 0;
            }
          });
      });
}
