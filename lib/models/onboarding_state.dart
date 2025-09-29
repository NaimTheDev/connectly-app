import '../models/app_user.dart';
import '../models/service_type.dart';

/// Represents the current state of user onboarding
class OnboardingState {
  final String userId;
  final String? email;
  final UserRole? selectedRole;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? imageUrl;
  final List<String> selectedCategories;
  final String? expertise;
  final ServiceType? selectedService;
  final double? virtualAppointmentPrice;
  final double? chatPrice;
  final String? goals;
  final List<String> interests;
  final bool isCalendlySetup;
  final bool isComplete;
  final int currentStep;
  final int totalSteps;

  const OnboardingState({
    required this.userId,
    this.email,
    this.selectedRole,
    this.firstName,
    this.lastName,
    this.bio,
    this.imageUrl,
    this.selectedCategories = const [],
    this.expertise,
    this.selectedService,
    this.virtualAppointmentPrice,
    this.chatPrice,
    this.goals,
    this.interests = const [],
    this.isCalendlySetup = false,
    this.isComplete = false,
    this.currentStep = 0,
    this.totalSteps = 7,
  });

  /// Create initial onboarding state for a user
  factory OnboardingState.initial(String userId, {String? email}) {
    return OnboardingState(userId: userId, email: email);
  }

  /// Create from Firestore map
  factory OnboardingState.fromMap(String userId, Map<String, dynamic> data) {
    return OnboardingState(
      userId: userId,
      email: data['email'] as String?,
      selectedRole: data['selectedRole'] != null
          ? (data['selectedRole'] == 'mentor'
                ? UserRole.mentor
                : UserRole.mentee)
          : null,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      bio: data['bio'] as String?,
      imageUrl: data['imageUrl'] as String?,
      selectedCategories: List<String>.from(data['selectedCategories'] ?? []),
      expertise: data['expertise'] as String?,
      selectedService: data['selectedService'] != null
          ? ServiceType.fromString(data['selectedService'])
          : null,
      virtualAppointmentPrice: (data['virtualAppointmentPrice'] as num?)
          ?.toDouble(),
      chatPrice: (data['chatPrice'] as num?)?.toDouble(),
      goals: data['goals'] as String?,
      interests: List<String>.from(data['interests'] ?? []),
      isCalendlySetup: data['isCalendlySetup'] ?? false,
      isComplete: data['isComplete'] ?? false,
      currentStep: data['currentStep'] ?? 0,
      totalSteps: data['totalSteps'] ?? 7,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'selectedRole': selectedRole?.name,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'imageUrl': imageUrl,
      'selectedCategories': selectedCategories,
      'expertise': expertise,
      'selectedService': selectedService?.toString(),
      'virtualAppointmentPrice': virtualAppointmentPrice,
      'chatPrice': chatPrice,
      'goals': goals,
      'interests': interests,
      'isCalendlySetup': isCalendlySetup,
      'isComplete': isComplete,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
    };
  }

  /// Copy with new values
  OnboardingState copyWith({
    String? email,
    UserRole? selectedRole,
    String? firstName,
    String? lastName,
    String? bio,
    String? imageUrl,
    List<String>? selectedCategories,
    String? expertise,
    ServiceType? selectedService,
    double? virtualAppointmentPrice,
    double? chatPrice,
    String? goals,
    List<String>? interests,
    bool? isCalendlySetup,
    bool? isComplete,
    int? currentStep,
    int? totalSteps,
  }) {
    return OnboardingState(
      userId: userId,
      email: email ?? this.email,
      selectedRole: selectedRole ?? this.selectedRole,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      expertise: expertise ?? this.expertise,
      selectedService: selectedService ?? this.selectedService,
      virtualAppointmentPrice:
          virtualAppointmentPrice ?? this.virtualAppointmentPrice,
      chatPrice: chatPrice ?? this.chatPrice,
      goals: goals ?? this.goals,
      interests: interests ?? this.interests,
      isCalendlySetup: isCalendlySetup ?? this.isCalendlySetup,
      isComplete: isComplete ?? this.isComplete,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  /// Calculate progress percentage
  double get progressPercentage => currentStep / totalSteps;

  /// Check if current step is valid for the selected role
  bool get canProceed {
    switch (currentStep) {
      case 0: // Welcome screen
        return true;
      case 1: // Role selection
        return selectedRole != null;
      case 2: // Basic profile
        return firstName?.isNotEmpty == true && lastName?.isNotEmpty == true;
      case 3: // Categories
        return selectedCategories.isNotEmpty;
      case 4: // Role-specific step 1
        if (selectedRole == UserRole.mentor) {
          return expertise?.isNotEmpty == true;
        } else {
          return goals?.isNotEmpty == true;
        }
      case 5: // Role-specific step 2
        if (selectedRole == UserRole.mentor) {
          return selectedService != null;
        } else {
          return true; // Mentees can proceed without additional requirements
        }
      case 6: // Final step
        return true;
      default:
        return false;
    }
  }

  /// Get total steps for the selected role
  int get totalStepsForRole {
    if (selectedRole == UserRole.mentor) {
      return 7; // Welcome, Role, Profile, Categories, Expertise, Services, Calendly, Complete
    } else {
      return 6; // Welcome, Role, Profile, Categories, Goals, Complete
    }
  }
}
