import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'auth_exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// google_sign_in 7.x requires an explicit, once-only [GoogleSignIn.initialize]
  /// before any other method (e.g. [GoogleSignIn.authenticate]). Cached so it
  /// runs exactly once for the lifetime of this service.
  Future<void>? _googleInitFuture;

  Stream<User?> get firebaseUserStream => _auth.authStateChanges();

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _buildAppUser(result.user);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

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
      return (_buildAppUserWithRole(result.user, role: role), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  Future<(AppUser?, bool)> signInWithGoogle() async {
    try {
      final result = await _googleSignInFlow();
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      return (await _buildAppUser(result.user), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  Future<(AppUser?, bool)> signUpWithGoogle(UserRole role) async {
    try {
      final result = await _googleSignInFlow();
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      return (_buildAppUserWithRole(result.user, role: role), isNew);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        throw const PasswordResetEmailNotFoundException();
      }
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    } catch (error) {
      throw AuthExceptionHandler.handleFirebaseAuthException(error);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Initializes [GoogleSignIn] exactly once. On Android no `serverClientId`
  /// is required here — the Gradle google-services plugin injects the web OAuth
  /// client (`client_type: 3`) from `google-services.json` as `default_web_client_id`.
  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitFuture ??= _googleSignIn.initialize();
  }

  Future<UserCredential> _googleSignInFlow() async {
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Builds an [AppUser] by fetching the stored role from Firestore.
  /// Falls back to [UserRole.mentee] when the document doesn't exist yet
  /// (e.g. during initial sign-up before the profile document is created).
  Future<AppUser?> _buildAppUser(User? user) async {
    if (user == null) return null;
    UserRole role = UserRole.mentee;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        role = (data['role'] == 'mentor') ? UserRole.mentor : UserRole.mentee;
      }
    } catch (_) {
      // Network error — proceed with default mentee role; role will be
      // corrected the next time the user's Firestore document is fetched.
    }
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      name: user.displayName,
      imageUrl: user.photoURL,
    );
  }

  /// Builds an [AppUser] with an explicitly provided role (used during sign-up
  /// before the Firestore profile document has been created).
  AppUser? _buildAppUserWithRole(User? user, {required UserRole role}) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      name: user.displayName,
      imageUrl: user.photoURL,
    );
  }
}
