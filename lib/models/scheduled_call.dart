import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_call.freezed.dart';
part 'scheduled_call.g.dart';

@freezed
abstract class ScheduledCall with _$ScheduledCall {
  const ScheduledCall._();

  const factory ScheduledCall({
    required String calendlyEventUri,
    // Firestore documents written by the webhook use snake_case for these two fields
    @JsonKey(name: 'cancel_url') required String cancelUrl,
    required DateTime createdAt,
    required String endTime,
    required String eventType,
    required String inviteeEmail,
    required String inviteeName,
    required String mentorUri,
    String? mentorName,
    String? payment,
    String? reconfirmation,
    @JsonKey(name: 'reschedule_url') required String rescheduleUrl,
    required bool rescheduled,
    required String startTime,
    required String status,
    required String timezone,
    String? joinUrl,
  }) = _ScheduledCall;

  factory ScheduledCall.fromJson(Map<String, dynamic> json) =>
      _$ScheduledCallFromJson(json);

  /// Reads a Firestore document, normalising the Timestamp to DateTime and
  /// handling both snake_case (webhook-written) and camelCase legacy keys.
  static ScheduledCall fromFirestore(Map<String, dynamic> data) {
    DateTime createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Support both snake_case (webhook) and camelCase (legacy inline writes)
    final cancelUrl =
        (data['cancel_url'] ?? data['cancelUrl'] ?? '') as String;
    final rescheduleUrl =
        (data['reschedule_url'] ?? data['rescheduleUrl'] ?? '') as String;

    return ScheduledCall(
      calendlyEventUri: data['calendlyEventUri'] as String? ?? '',
      cancelUrl: cancelUrl,
      createdAt: createdAt,
      endTime: data['endTime'] as String? ?? '',
      eventType: data['eventType'] as String? ?? '',
      inviteeEmail: data['inviteeEmail'] as String? ?? '',
      inviteeName: data['inviteeName'] as String? ?? '',
      mentorUri: data['mentorUri'] as String? ?? '',
      mentorName: data['mentorName'] as String?,
      payment: data['payment'] as String?,
      reconfirmation: data['reconfirmation'] as String?,
      rescheduleUrl: rescheduleUrl,
      rescheduled: data['rescheduled'] as bool? ?? false,
      startTime: data['startTime'] as String? ?? '',
      status: data['status'] as String? ?? '',
      timezone: data['timezone'] as String? ?? '',
      joinUrl: data['joinUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'calendlyEventUri': calendlyEventUri,
    'cancel_url': cancelUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'endTime': endTime,
    'eventType': eventType,
    'inviteeEmail': inviteeEmail,
    'inviteeName': inviteeName,
    'mentorUri': mentorUri,
    'mentorName': mentorName,
    'payment': payment,
    'reconfirmation': reconfirmation,
    'reschedule_url': rescheduleUrl,
    'rescheduled': rescheduled,
    'startTime': startTime,
    'status': status,
    'timezone': timezone,
    'joinUrl': joinUrl,
  };
}
