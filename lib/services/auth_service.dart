import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Stream of Firebase [User] objects for auth state changes.
  Stream<User?> get firebaseUserStream => _auth.authStateChanges();

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _userFromFirebase(result.user);
  }

  Future<AppUser?> signUpWithEmail(
    String email,
    String password,
    UserRole role,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // You should also save the role and other info to Firestore here
    return _userFromFirebase(result.user, role: role);
  }

  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return _userFromFirebase(result.user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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
