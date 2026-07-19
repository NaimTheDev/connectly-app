import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendly_invitee_resource.freezed.dart';
part 'calendly_invitee_resource.g.dart';

@freezed
abstract class CalendlyQuestionAnswer with _$CalendlyQuestionAnswer {
  const factory CalendlyQuestionAnswer({
    required String question,
    required String answer,
    required int position,
  }) = _CalendlyQuestionAnswer;

  factory CalendlyQuestionAnswer.fromJson(Map<String, dynamic> json) =>
      _$CalendlyQuestionAnswerFromJson(json);

  static CalendlyQuestionAnswer fromMap(Map<String, dynamic> data) {
    return CalendlyQuestionAnswer(
      question: data['question']?.toString() ?? '',
      answer: data['answer']?.toString() ?? '',
      position: data['position'] is int
          ? data['position'] as int
          : int.tryParse(data['position']?.toString() ?? '') ?? 0,
    );
  }
}

@freezed
abstract class CalendlyInviteeResource with _$CalendlyInviteeResource {
  const factory CalendlyInviteeResource({
    required String uri,
    required String email,
    required String name,
    required String status,
    required String event,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<CalendlyQuestionAnswer> questionsAndAnswers,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? timezone,
    bool? rescheduled,
    @JsonKey(name: 'cancel_url') String? cancelUrl,
    @JsonKey(name: 'reschedule_url') String? rescheduleUrl,
    @JsonKey(name: 'scheduling_method') String? schedulingMethod,
    @JsonKey(name: 'invitee_scheduled_by') String? inviteeScheduledBy,
    @JsonKey(name: 'text_reminder_number') String? textReminderNumber,
  }) = _CalendlyInviteeResource;

  factory CalendlyInviteeResource.fromJson(Map<String, dynamic> json) =>
      _$CalendlyInviteeResourceFromJson(json);

  static CalendlyInviteeResource fromMap(Map<String, dynamic> data) {
    DateTime parseDate(String? raw) {
      if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    final questions = (data['questions_and_answers'] as List<dynamic>?)
            ?.map((item) =>
                CalendlyQuestionAnswer.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        <CalendlyQuestionAnswer>[];

    return CalendlyInviteeResource(
      uri: data['uri']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      firstName: data['first_name']?.toString(),
      lastName: data['last_name']?.toString(),
      timezone: data['timezone']?.toString(),
      event: data['event']?.toString() ?? '',
      createdAt: parseDate(data['created_at']?.toString()),
      updatedAt: parseDate(data['updated_at']?.toString()),
      rescheduled: data['rescheduled'] as bool?,
      cancelUrl: data['cancel_url']?.toString(),
      rescheduleUrl: data['reschedule_url']?.toString(),
      schedulingMethod: data['scheduling_method']?.toString(),
      inviteeScheduledBy: data['invitee_scheduled_by']?.toString(),
      textReminderNumber: data['text_reminder_number']?.toString(),
      questionsAndAnswers: questions,
    );
  }
}
