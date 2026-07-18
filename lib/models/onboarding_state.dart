import 'package:freezed_annotation/freezed_annotation.dart';
import 'app_user.dart';
import 'service_type.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  const factory OnboardingState({
    required String userId,
    String? email,
    UserRole? selectedRole,
    String? firstName,
    String? lastName,
    String? bio,
    String? imageUrl,
    @Default([]) List<String> selectedCategories,
    String? expertise,
    ServiceType? selectedService,
    double? virtualAppointmentPrice,
    double? chatPrice,
    String? goals,
    @Default([]) List<String> interests,
    @Default(false) bool isCalendlySetup,
    @Default(false) bool isComplete,
    @Default(0) int currentStep,
    @Default(7) int totalSteps,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);

  factory OnboardingState.initial(String userId, {String? email}) =>
      OnboardingState(userId: userId, email: email);

  static OnboardingState fromMap(String userId, Map<String, dynamic> data) {
    return OnboardingState.fromJson({
      'userId': userId,
      'email': data['email'],
      'selectedRole': data['selectedRole'],
      'firstName': data['firstName'],
      'lastName': data['lastName'],
      'bio': data['bio'],
      'imageUrl': data['imageUrl'],
      'selectedCategories': data['selectedCategories'] ?? [],
      'expertise': data['expertise'],
      'selectedService': data['selectedService'],
      'virtualAppointmentPrice': data['virtualAppointmentPrice'],
      'chatPrice': data['chatPrice'],
      'goals': data['goals'],
      'interests': data['interests'] ?? [],
      'isCalendlySetup': data['isCalendlySetup'] ?? false,
      'isComplete': data['isComplete'] ?? false,
      'currentStep': data['currentStep'] ?? 0,
      'totalSteps': data['totalSteps'] ?? 7,
    });
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'selectedRole': selectedRole?.name,
    'firstName': firstName,
    'lastName': lastName,
    'bio': bio,
    'imageUrl': imageUrl,
    'selectedCategories': selectedCategories,
    'expertise': expertise,
    'selectedService': selectedService?.name,
    'virtualAppointmentPrice': virtualAppointmentPrice,
    'chatPrice': chatPrice,
    'goals': goals,
    'interests': interests,
    'isCalendlySetup': isCalendlySetup,
    'isComplete': isComplete,
    'currentStep': currentStep,
    'totalSteps': totalSteps,
  };

  double get progressPercentage => currentStep / totalSteps;

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return true;
      case 1:
        return selectedRole != null;
      case 2:
        return firstName?.isNotEmpty == true && lastName?.isNotEmpty == true;
      case 3:
        return selectedCategories.isNotEmpty;
      case 4:
        if (selectedRole == UserRole.mentor) {
          return expertise?.isNotEmpty == true;
        }
        return goals?.isNotEmpty == true;
      case 5:
        if (selectedRole == UserRole.mentor) {
          return selectedService != null;
        }
        return true;
      case 6:
        return true;
      default:
        return false;
    }
  }

  int get totalStepsForRole =>
      selectedRole == UserRole.mentor ? 7 : 6;
}
