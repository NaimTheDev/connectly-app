import 'package:firebase_auth/firebase_auth.dart';

/// Custom authentication exceptions with user-friendly messages
abstract class AuthException implements Exception {
  const AuthException(this.message, this.code);

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// Exception for invalid credentials (wrong email/password)
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super(
        'The email or password you entered is incorrect. Please try again.',
        'invalid-credential',
      );
}

/// Exception for user not found
class UserNotFoundException extends AuthException {
  const UserNotFoundException()
    : super(
        'No account found with this email address. Please check your email or sign up.',
        'user-not-found',
      );
}

/// Exception for wrong password
class WrongPasswordException extends AuthException {
  const WrongPasswordException()
    : super(
        'The password you entered is incorrect. Please try again.',
        'wrong-password',
      );
}

/// Exception for invalid email format
class InvalidEmailException extends AuthException {
  const InvalidEmailException()
    : super('Please enter a valid email address.', 'invalid-email');
}

/// Exception for weak password
class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super(
        'Password is too weak. Please choose a stronger password with at least 6 characters.',
        'weak-password',
      );
}

/// Exception for email already in use
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
    : super(
        'An account with this email already exists. Please sign in instead.',
        'email-already-in-use',
      );
}

/// Exception for too many requests
class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
    : super(
        'Too many unsuccessful attempts. Please try again later.',
        'too-many-requests',
      );
}

/// Exception for network errors
class NetworkException extends AuthException {
  const NetworkException()
    : super(
        'Network error. Please check your internet connection and try again.',
        'network-request-failed',
      );
}

/// Exception for Google Sign-In errors
class GoogleSignInException extends AuthException {
  const GoogleSignInException()
    : super(
        'Google Sign-In was cancelled or failed. Please try again.',
        'google-sign-in-failed',
      );
}

/// Exception for password reset email not found (specific case)
class PasswordResetEmailNotFoundException extends AuthException {
  const PasswordResetEmailNotFoundException()
    : super(
        'No account found with this email address. Please check your email or create an account.',
        'user-not-found-password-reset',
      );
}

/// Generic exception for unknown errors
class UnknownAuthException extends AuthException {
  const UnknownAuthException(String originalError)
    : super('An unexpected error occurred. Please try again.', 'unknown');
}

/// Utility class to convert Firebase auth exceptions to custom exceptions
class AuthExceptionHandler {
  static AuthException handleFirebaseAuthException(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return const InvalidCredentialsException();
        case 'user-not-found':
          return const UserNotFoundException();
        case 'wrong-password':
          return const WrongPasswordException();
        case 'invalid-email':
          return const InvalidEmailException();
        case 'weak-password':
          return const WeakPasswordException();
        case 'email-already-in-use':
          return const EmailAlreadyInUseException();
        case 'too-many-requests':
          return const TooManyRequestsException();
        case 'network-request-failed':
          return const NetworkException();
        default:
          return UnknownAuthException(error.toString());
      }
    }

    // Handle Google Sign-In specific errors
    if (error.toString().contains('google_sign_in')) {
      return const GoogleSignInException();
    }

    return UnknownAuthException(error.toString());
  }
}
