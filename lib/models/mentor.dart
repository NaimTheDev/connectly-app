import 'service_type.dart';

/// Mentor data model for Connectly app.
///
/// This class represents a mentor and includes serialization methods for
/// mapping to and from JSON and Map structures.
class Mentor {
  final String id;
  final String name;
  final String bio;
  final String expertise;
  final String? imageUrl;
  final String? calendlyUrl;
  final String? calendlyOrgId;
  final String? calendlyPAT;
  final String? calendlyUserUri;
  final List<String>? categories;
  final String? firstName;
  final String? lastName;
  final ServiceType? services;
  final double? virtualAppointmentPrice;
  final double? chatPrice;
  final bool isCalendlySetup;
  final bool? isHidden;

  const Mentor({
    required this.id,
    required this.name,
    required this.bio,
    required this.expertise,
    required this.imageUrl,
    this.calendlyUrl,
    this.calendlyOrgId,
    this.calendlyPAT,
    this.calendlyUserUri,
    this.categories,
    this.firstName,
    this.lastName,
    this.services,
    this.virtualAppointmentPrice,
    this.chatPrice,
    this.isCalendlySetup = false,
    this.isHidden,
  });

  /// Creates a Mentor from a Firestore map and document ID.
  factory Mentor.fromMap(String id, Map<String, dynamic> data) {
    return Mentor(
      id: id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      expertise: data['expertise'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      calendlyUrl: data['calendlyUrl'],
      calendlyOrgId: data['calendlyOrgId'],
      calendlyPAT: data['calendlyPAT'],
      calendlyUserUri: data['calendlyUserUri'],
      categories: (data['categories'] as List<dynamic>?)
          ?.map((cat) => cat.toString())
          .toList(),
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      services: data['services'] != null
          ? ServiceType.fromString(data['services'])
          : null,
      virtualAppointmentPrice: (data['virtualAppointmentPrice'] as num?)
          ?.toDouble(),
      chatPrice: (data['chatPrice'] as num?)?.toDouble(),
      isCalendlySetup: data['isCalendlySetup'] ?? false,
      isHidden: data['isHidden'],
    );
  }

  /// Creates a Mentor from a JSON map.
  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id'] ?? '',
      name: (json['firstName'] != null && json['lastName'] != null)
          ? '${json['firstName']} ${json['lastName']}'
          : (json['name'] ?? ''),
      bio: json['bio'] ?? '',
      expertise: json['expertise'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      calendlyUrl: json['calendlyUrl'],
      calendlyOrgId: json['calendlyOrgId'],
      calendlyPAT: json['calendlyPAT'],
      calendlyUserUri: json['calendlyUserUri'],
      categories: (json['categories'] as List<dynamic>?)
          ?.map((cat) => cat.toString())
          .toList(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      services: json['services'] != null
          ? ServiceType.fromString(json['services'])
          : null,
      virtualAppointmentPrice: (json['virtualAppointmentPrice'] as num?)
          ?.toDouble(),
      chatPrice: (json['chatPrice'] as num?)?.toDouble(),
      isCalendlySetup: json['isCalendlySetup'] ?? false,
    );
  }

  /// Converts Mentor to a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'expertise': expertise,
      'imageUrl': imageUrl,
      'calendlyUrl': calendlyUrl,
      'calendlyOrgId': calendlyOrgId,
      'calendlyPAT': calendlyPAT,
      'calendlyUserUri': calendlyUserUri,
      'categories': categories,
      'firstName': firstName,
      'lastName': lastName,
      'services': services?.toString(),
      'virtualAppointmentPrice': virtualAppointmentPrice,
      'chatPrice': chatPrice,
      'isCalendlySetup': isCalendlySetup,
    };
  }
}
