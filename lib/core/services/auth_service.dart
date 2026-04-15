import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(serverClientId: '733225462613-4l9qjslf6i2q2us6oj8h7lh7otdnsjj2.apps.googleusercontent.com');

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Native Flutter Google Sign-In
  // This permanently fixes the Google Play Services spinning issue
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On Web, google_sign_in v7 throws "authenticate is not supported"
        // because it strictly enforces HTML buttons.
        // Firebase natively supports signInWithPopup on custom Flutter buttons!
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(provider);
      } else {
        // On Android / iOS, we use the native google_sign_in plugin
        GoogleSignInAccount? googleUser;
        try {
          googleUser = await _googleSignIn.authenticate();
        } catch (signInError, signInStack) {
          // Print exact error so it is never silent in the logs
          debugPrint('══════════════════════════════════════════════');
          debugPrint('❌ Google Sign-In ERROR: $signInError');
          debugPrint('📍 Stack trace: $signInStack');
          debugPrint('══════════════════════════════════════════════');
          rethrow;
        }

        final GoogleSignInAuthentication auth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e, stack) {
      debugPrint('══════════════════════════════════════════════');
      debugPrint('❌ Google Sign-In FATAL: $e');
      debugPrint('📍 Stack: $stack');
      debugPrint('══════════════════════════════════════════════');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Email/Password login
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Email Sign-In failed: $e');
    }
  }

  // Email/Password register
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
