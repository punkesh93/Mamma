import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _userData;
  firebase_auth.User? _firebaseUser;
  bool _isLoading = true;

  UserModel? get userData => _userData;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        _firestoreService.streamUser(user.uid).listen((data) {
          _userData = data;
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _userData = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _syncUserToFirestore(firebase_auth.User user) async {
    try {
      final existing = await _firestoreService.getUser(user.uid);
      if (existing == null) {
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'New Mom',
          email: user.email,
          photoUrl: user.photoURL,
          currentWeek: 4,
          country: 'US',
          language: 'en',
          streakDays: 0,
          totalPoints: 0,
          plan: 'trial',
          trialStartDate: DateTime.now().toIso8601String(),
          isPremium: true, // Trial users are premium
          quietMode: false,
          units: 'imperial',
          createdAt: DateTime.now().toIso8601String(),
          region: 'US',
        );
        await _firestoreService.createUser(newUser);
      }
    } catch (e) {
      debugPrint("Error syncing user to Firestore: $e");
      // We don't rethrow here so the user can still enter the app 
      // even if Firestore sync fails temporarily.
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred?.user != null) {
        await _syncUserToFirestore(cred!.user!);
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _authService.signInWithEmail(email: email, password: password);
      if (cred.user != null) {
        await _syncUserToFirestore(cred.user!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _authService.registerWithEmail(email: email, password: password);
      if (cred.user != null) {
        await _syncUserToFirestore(cred.user!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email: email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> saveUserData(UserModel user) async {
    _userData = user;
    notifyListeners();
    try {
      await _firestoreService.createUser(user);
    } catch (e) {
      debugPrint("Error saving user data: $e");
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    if (_firebaseUser != null) {
      await _firebaseUser!.reload();
      final updatedUser = await _firestoreService.getUser(_firebaseUser!.uid);
      if (updatedUser != null) {
        _userData = updatedUser;
        notifyListeners();
      }
    }
  }
}
