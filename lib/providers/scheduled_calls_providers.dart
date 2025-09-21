import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scheduled_call.dart';

/// Authenticated user's scheduled calls (supports both subcollection names)
final scheduledCallsProvider =
    FutureProvider.family<List<ScheduledCall>, String>((ref, uid) async {
      final calls = <ScheduledCall>[];

      // scheduledCalls (legacy)
      final legacySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scheduledCalls')
          .get();
      calls.addAll(
        legacySnap.docs.map((doc) {
          final data = doc.data();
          return ScheduledCall(
            calendlyEventUri: data['calendlyEventUri'] ?? '',
            cancelUrl: data['cancelUrl'] ?? '',
            createdAt: data['createdAt'],
            endTime: data['endTime'] ?? '',
            eventType: data['eventType'] ?? '',
            inviteeEmail: data['inviteeEmail'] ?? '',
            inviteeName: data['inviteeName'] ?? '',
            mentorUri: data['mentorUri'] ?? '',
            noShow: data['noShow'],
            payment: data['payment'],
            reconfirmation: data['reconfirmation'],
            rescheduleUrl: data['rescheduleUrl'] ?? '',
            rescheduled: data['rescheduled'] ?? false,
            startTime: data['startTime'] ?? '',
            status: data['status'] ?? '',
            timezone: data['timezone'] ?? '',
            joinUrl: data['joinUrl'],
          );
        }),
      );

      // scheduled_calls (new)
      final newSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scheduled_calls')
          .get();
      calls.addAll(
        newSnap.docs.map((doc) {
          final data = doc.data();
          return ScheduledCall(
            calendlyEventUri: data['calendlyEventUri'] ?? '',
            cancelUrl: data['cancelUrl'] ?? '',
            createdAt: data['createdAt'],
            endTime: data['endTime'] ?? '',
            eventType: data['eventType'] ?? '',
            inviteeEmail: data['inviteeEmail'] ?? '',
            inviteeName: data['inviteeName'] ?? '',
            mentorUri: data['mentorUri'] ?? '',
            noShow: data['noShow'],
            payment: data['payment'],
            reconfirmation: data['reconfirmation'],
            rescheduleUrl: data['rescheduleUrl'] ?? '',
            rescheduled: data['rescheduled'] ?? false,
            startTime: data['startTime'] ?? '',
            status: data['status'] ?? '',
            timezone: data['timezone'] ?? '',
            joinUrl: data['joinUrl'],
          );
        }),
      );

      return calls;
    });
