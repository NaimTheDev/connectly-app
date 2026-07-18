import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole {
  @JsonValue('mentor')
  mentor,
  @JsonValue('mentee')
  mentee,
}

@freezed
class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required String email,
    required UserRole role,
    String? imageUrl,
    String? name,
    String? firstName,
    String? lastName,
    String? bio,
    List<String>? interests,
    String? goals,
    @Default(false) bool isOnboardingComplete,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    final name = (firstName != null && lastName != null)
        ? '$firstName $lastName'
        : data['name'] as String?;
    return AppUser.fromJson({
      'uid': uid,
      'email': data['email'] ?? '',
      'role': data['role'] ?? 'mentee',
      'imageUrl': data['imageUrl'],
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'bio': data['bio'],
      'interests': data['interests'],
      'goals': data['goals'],
      'isOnboardingComplete': data['isOnboardingComplete'] ?? false,
    });
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role.name,
    'name': '${firstName ?? ''}${lastName != null ? ' $lastName' : ''}',
    'imageUrl': imageUrl,
    'firstName': firstName,
    'lastName': lastName,
    'bio': bio,
    'interests': interests,
    'goals': goals,
    'isOnboardingComplete': isOnboardingComplete,
  };
}
