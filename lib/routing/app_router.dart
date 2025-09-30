import 'package:flutter/material.dart';
import '../screens/screens.dart';
import '../screens/onboarding/onboarding_flow_screen.dart';
import '../screens/password_reset_screen.dart';
import '../models/chat.dart';

/// Arguments for ChatScreen navigation
class ChatScreenArguments {
  final Chat chat;
  final String otherParticipantId;
  final String? otherParticipantName;

  const ChatScreenArguments({
    required this.chat,
    required this.otherParticipantId,
    this.otherParticipantName,
  });
}

/// Simple app router using named routes
class AppRouter {
  static const String home = '/';
  static const String messages = '/messages';
  static const String mentors = '/mentors';
  static const String calls = '/calls';
  static const String settings = '/settings';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String passwordReset = '/password-reset';
  static const String mentorDetail = '/mentor';
  static const String chat = '/chat';
  static const String onboarding = '/onboarding';

  static Map<String, WidgetBuilder> get routes => {
    signIn: (context) => const SignInScreen(),
    signUp: (context) => const SignUpScreen(),
    passwordReset: (context) => const PasswordResetScreen(),
    onboarding: (context) => const OnboardingFlowScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(
          builder: (context) => const SignInScreen(),
          settings: settings,
        );
      case signUp:
        return MaterialPageRoute(
          builder: (context) => const SignUpScreen(),
          settings: settings,
        );
      case passwordReset:
        return MaterialPageRoute(
          builder: (context) => const PasswordResetScreen(),
          settings: settings,
        );
      case chat:
        // Expect ChatScreenArguments to be passed
        final args = settings.arguments as ChatScreenArguments?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: args.chat,
              otherParticipantId: args.otherParticipantId,
              otherParticipantName: args.otherParticipantName,
            ),
            settings: settings,
          );
        }
        return null;
      default:
        // For mentor detail routes like '/mentor/123'
        if (settings.name?.startsWith('/mentor/') == true) {
          final mentorId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => MentorDetailScreen(mentorId: mentorId),
            settings: settings,
          );
        }
        return null;
    }
  }
}
