import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/onboarding_state.dart';
import '../models/app_user.dart';
import '../models/service_type.dart';

/// Provider for onboarding service
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Provider to check if user needs onboarding
final needsOnboardingProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) return true;

    final userData = userDoc.data()!;
    return !(userData['isOnboardingComplete'] ?? false);
  } catch (e) {
    return true; // Default to needing onboarding if error
  }
});

/// Provider for current onboarding state
final onboardingStateProvider = FutureProvider.family<OnboardingState?, String>(
  (ref, userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('onboarding')
          .doc(userId)
          .get();

      if (doc.exists) {
        return OnboardingState.fromMap(userId, doc.data()!);
      } else {
        return OnboardingState.initial(userId);
      }
    } catch (e) {
      return OnboardingState.initial(userId);
    }
  },
);

/// Provider for predefined categories
final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'Addiction',
    'Advisory',
    'Arabic Studies',
    'Architecture',
    'Art',
    'Business',
    'Career Planning',
    'Charity & Non-Profits',
    'Coaching',
    'Comedy',
    'Content Creation',
    'Dawah',
    'Debate & Apologetics',
    'E-Commerce',
    'Education',
    'Entertainment',
    'Entrepreneurship',
    'Faith & Spirituality',
    'Family',
    'Fiqh Studies',
    'Fitness & Nutrition',
    'Hadith Studies',
    'Health & Wellness',
    'Home Economics',
    'Islamic Finance',
    'Marriage',
    'Martial Arts',
    'Mental Health',
    'Parenting',
    'Personal Finance',
    'Philosophy',
    'Podcasting',
    'Politics',
    'Public Speaking',
    'Quran Studies',
    'Real Estate',
    'Relationships',
    'Self-Improvement',
    'Stocks & Crypto Trading',
    'Strength & Conditioning',
    'Theology',
    'Therapy',
    'Wealth Management',
  ];
});

/// Service class for managing onboarding operations
class OnboardingService {
  /// Initialize onboarding for a user
  Future<OnboardingState> initializeOnboarding(String userId) async {
    try {
      // Get user's email from Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final email = firebaseUser?.email;

      // Check if onboarding state exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('onboarding')
          .doc(userId)
          .get();

      if (doc.exists) {
        // Load existing onboarding state, but ensure email is set
        final existingState = OnboardingState.fromMap(userId, doc.data()!);
        if (existingState.email == null && email != null) {
          // Update with email if missing
          final updatedState = existingState.copyWith(email: email);
          await _saveState(updatedState);
          return updatedState;
        }
        return existingState;
      } else {
        // Create new onboarding state with email
        final initialState = OnboardingState.initial(userId, email: email);
        await _saveState(initialState);
        return initialState;
      }
    } catch (e) {
      // If error, create initial state
      final firebaseUser = FirebaseAuth.instance.currentUser;
      return OnboardingState.initial(userId, email: firebaseUser?.email);
    }
  }

  /// Update role selection
  Future<OnboardingState> updateRole(
    OnboardingState currentState,
    UserRole role,
  ) async {
    final newState = currentState.copyWith(
      selectedRole: role,
      currentStep: 2,
      totalSteps: role == UserRole.mentor ? 7 : 6,
    );
    // Persist both onboarding state and early user role so the rest of the
    // app (and analytics/security rules) can immediately rely on `users/{id}.role`.
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(currentState.userId);

      // Write onboarding state (merge keeps any partial previously stored fields)
      final onboardingWrite = _saveState(newState);

      // Write/merge role onto user doc without overwriting other fields.
      final userRoleWrite = userRef.set({
        'role': role.name,
      }, SetOptions(merge: true));

      await Future.wait([onboardingWrite, userRoleWrite]);
    } catch (e) {
      // Silent catch; onboarding flow can continue – role will be written again on completion.
    }
    return newState;
  }

  /// Update basic profile information
  Future<OnboardingState> updateBasicProfile(
    OnboardingState currentState, {
    required String firstName,
    required String lastName,
    String? bio,
    String? imageUrl,
  }) async {
    final newState = currentState.copyWith(
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      imageUrl: imageUrl,
      currentStep: 3,
    );

    await _saveState(newState);
    return newState;
  }

  /// Update selected categories
  Future<OnboardingState> updateCategories(
    OnboardingState currentState,
    List<String> categories,
  ) async {
    final newState = currentState.copyWith(
      selectedCategories: categories,
      currentStep: 4,
    );

    await _saveState(newState);
    return newState;
  }

  /// Update mentor expertise
  Future<OnboardingState> updateExpertise(
    OnboardingState currentState,
    String expertise,
  ) async {
    if (currentState.selectedRole != UserRole.mentor) {
      throw Exception('Only mentors can set expertise');
    }

    final newState = currentState.copyWith(
      expertise: expertise,
      currentStep: 5,
    );

    await _saveState(newState);
    return newState;
  }

  /// Update mentor services and pricing
  Future<OnboardingState> updateServices(
    OnboardingState currentState, {
    required ServiceType service,
    double? virtualAppointmentPrice,
    double? chatPrice,
  }) async {
    if (currentState.selectedRole != UserRole.mentor) {
      throw Exception('Only mentors can set services');
    }

    final newState = currentState.copyWith(
      selectedService: service,
      virtualAppointmentPrice: virtualAppointmentPrice,
      chatPrice: chatPrice,
      currentStep: 6,
    );

    await _saveState(newState);
    return newState;
  }

  /// Update mentee goals and interests
  Future<OnboardingState> updateGoalsAndInterests(
    OnboardingState currentState, {
    required String goals,
    required List<String> interests,
  }) async {
    if (currentState.selectedRole != UserRole.mentee) {
      throw Exception('Only mentees can set goals and interests');
    }

    final newState = currentState.copyWith(
      goals: goals,
      interests: interests,
      currentStep: 5,
    );

    await _saveState(newState);
    return newState;
  }

  /// Update Calendly setup status
  Future<OnboardingState> updateCalendlySetup(
    OnboardingState currentState,
    bool isSetup,
  ) async {
    final newState = currentState.copyWith(
      isCalendlySetup: isSetup,
      currentStep: currentState.selectedRole == UserRole.mentor
          ? 7
          : currentState.currentStep,
    );

    await _saveState(newState);
    return newState;
  }

  /// Complete onboarding and save to user profile
  Future<void> completeOnboarding(OnboardingState currentState) async {
    try {
      final userId = currentState.userId;
      print('🚀 Starting onboarding completion for user: $userId');
      print('📋 User role: ${currentState.selectedRole?.name}');

      final batch = FirebaseFirestore.instance.batch();

      // Update user document
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userData = {
        'email': currentState.email,
        'firstName': currentState.firstName,
        'lastName': currentState.lastName,
        'name': '${currentState.firstName} ${currentState.lastName}',
        'bio': currentState.bio,
        'imageUrl': currentState.imageUrl,
        'isOnboardingComplete': true,
        // Ensure role is present/finalized on the user document.
        if (currentState.selectedRole != null)
          'role': currentState.selectedRole!.name,
      };

      // Add role-specific data
      if (currentState.selectedRole == UserRole.mentee) {
        userData.addAll({
          'goals': currentState.goals,
          'interests': currentState.interests,
        });
      }

      print('📝 BATCH OPERATION 1: SET users/$userId (with merge)');
      print('   Data: $userData');
      batch.set(userRef, userData, SetOptions(merge: true));

      // If mentor, create/update mentor document
      if (currentState.selectedRole == UserRole.mentor) {
        final mentorRef = FirebaseFirestore.instance
            .collection('mentors')
            .doc(userId);
        final mentorData = {
          'name': '${currentState.firstName} ${currentState.lastName}',
          'firstName': currentState.firstName,
          'lastName': currentState.lastName,
          'bio': currentState.bio ?? '',
          'expertise': currentState.expertise ?? '',
          'imageUrl': currentState.imageUrl,
          'categories': currentState.selectedCategories,
          'services': currentState.selectedService?.toString(),
          'virtualAppointmentPrice': currentState.virtualAppointmentPrice,
          'chatPrice': currentState.chatPrice,
          'isCalendlySetup': currentState.isCalendlySetup,
        };

        print('📝 BATCH OPERATION 2: SET mentors/$userId');
        print('   Data: $mentorData');
        batch.set(mentorRef, mentorData);
      }

      // Mark onboarding as complete
      final onboardingRef = FirebaseFirestore.instance
          .collection('onboarding')
          .doc(userId);
      final onboardingData = {
        'isComplete': true,
        'currentStep': currentState.totalStepsForRole,
      };

      print('📝 BATCH OPERATION 3: SET onboarding/$userId (with merge)');
      print('   Data: $onboardingData');
      batch.set(onboardingRef, onboardingData, SetOptions(merge: true));

      print(
        '💾 Committing batch with ${currentState.selectedRole == UserRole.mentor ? 3 : 2} operations...',
      );
      await batch.commit();
      print('✅ Batch commit successful!');
    } catch (e) {
      print('❌ Batch commit failed: $e');
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  /// Go to next step
  Future<OnboardingState> nextStep(OnboardingState currentState) async {
    if (currentState.canProceed &&
        currentState.currentStep < currentState.totalStepsForRole) {
      final newState = currentState.copyWith(
        currentStep: currentState.currentStep + 1,
      );
      await _saveState(newState);
      return newState;
    }
    return currentState;
  }

  /// Go to previous step
  Future<OnboardingState> previousStep(OnboardingState currentState) async {
    if (currentState.currentStep > 0) {
      final newState = currentState.copyWith(
        currentStep: currentState.currentStep - 1,
      );
      await _saveState(newState);
      return newState;
    }
    return currentState;
  }

  /// Save current state to Firestore
  Future<void> _saveState(OnboardingState state) async {
    try {
      await FirebaseFirestore.instance
          .collection('onboarding')
          .doc(state.userId)
          .set(state.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Handle error silently for now
    }
  }
}
