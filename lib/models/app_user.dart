/// Defines user roles in the app.
enum UserRole { mentor, mentee }

/// Immutable user model for authentication and profile data.
class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String? imageUrl;
  final String? name;
  final String? firstName;
  final String? lastName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.imageUrl,
    this.name,
    this.firstName,
    this.lastName,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final roleString = data['role'] as String?;
    final role = roleString == 'mentor' ? UserRole.mentor : UserRole.mentee;
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    final name = (firstName != null && lastName != null)
        ? '$firstName $lastName'
        : data['name'] as String?;
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: role,
      imageUrl: data['imageUrl'] as String?,
      name: name,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role.name,
    'name': (firstName ?? '') + (lastName != null ? ' $lastName' : ''),
    'imageUrl': imageUrl,
    'firstName': firstName,
    'lastName': lastName,
  };
}
