class CalendlyQuestionAnswer {
  final String question;
  final String answer;
  final int position;

  const CalendlyQuestionAnswer({
    required this.question,
    required this.answer,
    required this.position,
  });

  factory CalendlyQuestionAnswer.fromMap(Map<String, dynamic> data) {
    return CalendlyQuestionAnswer(
      question: data['question']?.toString() ?? '',
      answer: data['answer']?.toString() ?? '',
      position: data['position'] is int
          ? data['position'] as int
          : int.tryParse(data['position']?.toString() ?? '') ?? 0,
    );
  }
}

class CalendlyInviteeResource {
  final String uri;
  final String email;
  final String name;
  final String status;
  final String? firstName;
  final String? lastName;
  final String? timezone;
  final String event;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? rescheduled;
  final String? cancelUrl;
  final String? rescheduleUrl;
  final String? schedulingMethod;
  final String? inviteeScheduledBy;
  final String? textReminderNumber;
  final List<CalendlyQuestionAnswer> questionsAndAnswers;

  const CalendlyInviteeResource({
    required this.uri,
    required this.email,
    required this.name,
    required this.status,
    required this.event,
    required this.createdAt,
    required this.updatedAt,
    required this.questionsAndAnswers,
    this.firstName,
    this.lastName,
    this.timezone,
    this.rescheduled,
    this.cancelUrl,
    this.rescheduleUrl,
    this.schedulingMethod,
    this.inviteeScheduledBy,
    this.textReminderNumber,
  });

  factory CalendlyInviteeResource.fromMap(Map<String, dynamic> data) {
    final questions = (data['questions_and_answers'] as List<dynamic>?)
            ?.map((item) => CalendlyQuestionAnswer.fromMap(
                  Map<String, dynamic>.from(
                    item as Map<dynamic, dynamic>,
                  ),
                ))
            .toList() ??
        <CalendlyQuestionAnswer>[];

    DateTime parseDate(String? raw) {
      if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

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
