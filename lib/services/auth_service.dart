import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'auth_exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Stream of Firebase [User] objects for auth state changes.
  Stream<User?> get firebaseUserStream => _auth.authStateChanges();

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  /// Sign up with email/password and return both the created user (as [AppUser])
  /// and a boolean flag indicating whether this is a brand new account.
  ///
  /// Returns a record: `(user, isNewUser)`.
  Future<(AppUser?, bool)> signUpWithEmail(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final isNew = result.additionalUserInfo?.isNewUser ?? true;
      return (_userFromFirebase(result.user, role: role), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  /// Sign in with Google and return `(user, isNewUser)`.
  Future<(AppUser?, bool)> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      return (_userFromFirebase(result.user), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  /// Sign up with Google and return `(user, isNewUser)`.
  Future<(AppUser?, bool)> signUpWithGoogle(UserRole role) async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      return (_userFromFirebase(result.user, role: role), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Sends a password reset email to the given email address.
  ///
  /// Throws [AuthException] with user-friendly error messages.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Use specific password reset exception for user-not-found in this context
      if (error.code == 'user-not-found') {
        throw const PasswordResetEmailNotFoundException();
      }
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  AppUser? _userFromFirebase(User? user, {UserRole? role}) {
    if (user == null) return null;
    // You should fetch additional user info from Firestore here
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: role ?? UserRole.mentee,
      name: user.displayName,
      imageUrl: user.photoURL,
    );
  }
}
