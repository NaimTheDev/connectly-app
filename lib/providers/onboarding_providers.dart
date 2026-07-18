import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/onboarding_state.dart';
import '../models/app_user.dart';
import '../models/service_type.dart';

part 'onboarding_providers.g.dart';

@Riverpod(keepAlive: true)
OnboardingService onboardingService(OnboardingServiceRef ref) =>
    OnboardingService();

@riverpod
Future<bool> needsOnboarding(NeedsOnboardingRef ref, String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (!userDoc.exists) return true;
    return !(userDoc.data()!['isOnboardingComplete'] as bool? ?? false);
  } catch (_) {
    return true;
  }
}

@riverpod
Future<OnboardingState?> onboardingState(
  OnboardingStateRef ref,
  String userId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('onboarding')
        .doc(userId)
        .get();
    return doc.exists
        ? OnboardingState.fromMap(userId, doc.data()!)
        : OnboardingState.initial(userId);
  } catch (_) {
    return OnboardingState.initial(userId);
  }
}

@Riverpod(keepAlive: true)
List<String> categories(CategoriesRef ref) => const [
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

// ── OnboardingService ─────────────────────────────────────────────────────────

class OnboardingService {
  Future<OnboardingState> initializeOnboarding(String userId) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final email = firebaseUser?.email;
      final doc = await FirebaseFirestore.instance
          .collection('onboarding')
          .doc(userId)
          .get();
      if (doc.exists) {
        final existing = OnboardingState.fromMap(userId, doc.data()!);
        if (existing.email == null && email != null) {
          final updated = existing.copyWith(email: email);
          await _saveState(updated);
          return updated;
        }
        return existing;
      }
      final initial = OnboardingState.initial(userId, email: email);
      await _saveState(initial);
      return initial;
    } catch (_) {
      return OnboardingState.initial(
        userId,
        email: FirebaseAuth.instance.currentUser?.email,
      );
    }
  }

  Future<OnboardingState> updateRole(
    OnboardingState currentState,
    UserRole role,
  ) async {
    final newState = currentState.copyWith(
      selectedRole: role,
      currentStep: 2,
      totalSteps: role == UserRole.mentor ? 7 : 6,
    );
    try {
      final firestore = FirebaseFirestore.instance;
      await Future.wait([
        _saveState(newState),
        firestore.collection('users').doc(currentState.userId).set(
          {'role': role.name},
          SetOptions(merge: true),
        ),
      ]);
    } catch (_) {
      // Role is written again on completion — safe to continue.
    }
    return newState;
  }

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

  Future<OnboardingState> updateCategories(
    OnboardingState currentState,
    List<String> categories,
  ) async {
    final newState =
        currentState.copyWith(selectedCategories: categories, currentStep: 4);
    await _saveState(newState);
    return newState;
  }

  Future<OnboardingState> updateExpertise(
    OnboardingState currentState,
    String expertise,
  ) async {
    if (currentState.selectedRole != UserRole.mentor) {
      throw Exception('Only mentors can set expertise');
    }
    final newState =
        currentState.copyWith(expertise: expertise, currentStep: 5);
    await _saveState(newState);
    return newState;
  }

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

  Future<void> completeOnboarding(OnboardingState currentState) async {
    final userId = currentState.userId;
    final batch = FirebaseFirestore.instance.batch();

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    final userData = <String, dynamic>{
      'email': currentState.email,
      'firstName': currentState.firstName,
      'lastName': currentState.lastName,
      'name': '${currentState.firstName} ${currentState.lastName}',
      'bio': currentState.bio,
      'imageUrl': currentState.imageUrl,
      'isOnboardingComplete': true,
      if (currentState.selectedRole != null)
        'role': currentState.selectedRole!.name,
    };

    if (currentState.selectedRole == UserRole.mentee) {
      userData.addAll({
        'goals': currentState.goals,
        'interests': currentState.interests,
      });
    }

    batch.set(userRef, userData, SetOptions(merge: true));

    if (currentState.selectedRole == UserRole.mentor) {
      final mentorRef =
          FirebaseFirestore.instance.collection('mentors').doc(userId);
      batch.set(mentorRef, {
        'name': '${currentState.firstName} ${currentState.lastName}',
        'firstName': currentState.firstName,
        'lastName': currentState.lastName,
        'bio': currentState.bio ?? '',
        'expertise': currentState.expertise ?? '',
        'imageUrl': currentState.imageUrl,
        'categories': currentState.selectedCategories,
        'services': currentState.selectedService?.name,
        'virtualAppointmentPrice': currentState.virtualAppointmentPrice,
        'chatPrice': currentState.chatPrice,
        'isCalendlySetup': currentState.isCalendlySetup,
        'isHidden': false,
      });
    }

    final onboardingRef =
        FirebaseFirestore.instance.collection('onboarding').doc(userId);
    batch.set(
      onboardingRef,
      {'isComplete': true, 'currentStep': currentState.totalStepsForRole},
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('completeOnboarding: batch commit failed — $e');
      throw Exception('Failed to complete onboarding: $e');
    }
  }

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

  Future<void> _saveState(OnboardingState state) async {
    try {
      await FirebaseFirestore.instance
          .collection('onboarding')
          .doc(state.userId)
          .set(state.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('OnboardingService._saveState: $e');
    }
  }
}
