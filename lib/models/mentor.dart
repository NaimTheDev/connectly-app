import 'package:freezed_annotation/freezed_annotation.dart';
import 'service_type.dart';

part 'mentor.freezed.dart';
part 'mentor.g.dart';

@freezed
abstract class Mentor with _$Mentor {
  const Mentor._();

  const factory Mentor({
    required String id,
    required String name,
    required String bio,
    required String expertise,
    String? imageUrl,
    String? calendlyUrl,
    String? calendlyOrgId,
    // calendlyPAT is intentionally omitted — PATs are server-side only
    String? calendlyUserUri,
    List<String>? categories,
    String? firstName,
    String? lastName,
    ServiceType? services,
    double? virtualAppointmentPrice,
    double? chatPrice,
    @Default(false) bool isCalendlySetup,
    bool? isHidden,
    bool? inAppScheduling,
  }) = _Mentor;

  factory Mentor.fromJson(Map<String, dynamic> json) =>
      _$MentorFromJson(json);

  static Mentor fromMap(String id, Map<String, dynamic> data) {
    return Mentor(
      id: id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      expertise: data['expertise'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      calendlyUrl: data['calendlyUrl'] as String?,
      calendlyOrgId: data['calendlyOrgId'] as String?,
      calendlyUserUri: data['calendlyUserUri'] as String?,
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      services: data['services'] != null
          ? ServiceType.fromString(data['services'] as String)
          : null,
      virtualAppointmentPrice:
          (data['virtualAppointmentPrice'] as num?)?.toDouble(),
      chatPrice: (data['chatPrice'] as num?)?.toDouble(),
      isCalendlySetup: data['isCalendlySetup'] as bool? ?? false,
      isHidden: data['isHidden'] as bool?,
      inAppScheduling: data['inAppScheduling'] as bool?,
    );
  }

  static Mentor fromApiJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id'] as String? ?? '',
      name: (json['firstName'] != null && json['lastName'] != null)
          ? '${json['firstName']} ${json['lastName']}'
          : (json['name'] as String? ?? ''),
      bio: json['bio'] as String? ?? '',
      expertise: json['expertise'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      calendlyUrl: json['calendlyUrl'] as String?,
      calendlyOrgId: json['calendlyOrgId'] as String?,
      calendlyUserUri: json['calendlyUserUri'] as String?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      services: json['services'] != null
          ? ServiceType.fromString(json['services'] as String)
          : null,
      virtualAppointmentPrice:
          (json['virtualAppointmentPrice'] as num?)?.toDouble(),
      chatPrice: (json['chatPrice'] as num?)?.toDouble(),
      isCalendlySetup: json['isCalendlySetup'] as bool? ?? false,
      inAppScheduling: json['inAppScheduling'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bio': bio,
    'expertise': expertise,
    'imageUrl': imageUrl,
    'calendlyUrl': calendlyUrl,
    'calendlyOrgId': calendlyOrgId,
    'calendlyUserUri': calendlyUserUri,
    'categories': categories,
    'firstName': firstName,
    'lastName': lastName,
    'services': services?.name,
    'virtualAppointmentPrice': virtualAppointmentPrice,
    'chatPrice': chatPrice,
    'isCalendlySetup': isCalendlySetup,
  };
}
