import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';
import 'local_service.dart';
import 'default_admin_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();
  final MessagingService _msg = MessagingService();
  final LocalService _local = LocalService();

  User? _firebaseUser;
  AppUser? _appUser;
  bool _initializing = true;
  bool _darkMode = false;
  Locale _locale = const Locale('en');

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get initializing => _initializing;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _appUser?.isAdmin == true;
  bool get isPending => _appUser?.role == 'pending_admin';
  bool get isBanned => _appUser?.banned == true;
  bool get darkMode => _darkMode;
  Locale get locale => _locale;
  FirestoreService get db => _db;
  LocalService get local => _local;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Load local preferences (fast)
      _darkMode = await _local.getDarkMode();
      _locale = Locale(await _local.getLocale());
      notifyListeners();

      // Ensure the default super-admin exists with a timeout
      try {
        await DefaultAdminService.ensureDefaultAdmin()
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ DefaultAdminService error/timeout: $e – continuing');
      }

      // Start listening to Firebase Auth state
      _auth.userStream.listen(_onAuthChanged);

      // Fallback: if auth stream never fires, force `initializing = false` after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (_initializing) {
          debugPrint('⚠️ Auth stream timed out – forcing init done');
          _initializing = false;
          _firebaseUser = _auth.currentUser;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('❌ AppProvider init error: $e');
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      // Stream live user doc changes
      _auth.appUserStream(user.uid).listen((u) {
        _appUser = u;
        notifyListeners();
      });
      // Init FCM notifications (non‑blocking)
      try {
        await _msg.init(user.uid);
      } catch (e) {
        debugPrint('FCM init: $e');
      }
    } else {
      _appUser = null;
    }
    _initializing = false;
    notifyListeners();
  }

  // ── Theme / Locale ─────────────────────────────────────────────────────
  Future<void> toggleDarkMode(bool v) async {
    _darkMode = v;
    await _local.setDarkMode(v);
    notifyListeners();
  }

  Future<void> setLocale(String lang) async {
    _locale = Locale(lang);
    await _local.setLocale(lang);
    notifyListeners();
  }

  // ── Auth ───────────────────────────────────────────────────────────────
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signIn(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    }
  }

  Future<String?> signUpUser(String email, String password, String name) async {
    try {
      await _auth.signUpUser(
          email: email, password: password, displayName: name);
      await _db.seedIfEmpty();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    }
  }

  Future<String?> requestAdminAccount({
    required String email,
    required String password,
    required String name,
    required String reason,
    required String organization,
  }) async {
    try {
      await _auth.requestAdminAccount(
        email: email,
        password: password,
        displayName: name,
        reason: reason,
        organization: organization,
      );
      await _db.seedIfEmpty();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not signed in');
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password));
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendly(e.code));
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendly(e.code));
    }
  }

  String _friendly(String code) {
    const m = {
      'user-not-found': 'No account found with that email.',
      'wrong-password': 'Incorrect password.',
      'invalid-credential': 'Invalid email or password.',
      'email-already-in-use': 'Email already registered.',
      'weak-password': 'Password must be at least 6 characters.',
      'invalid-email': 'Please enter a valid email address.',
      'too-many-requests': 'Too many attempts. Try again later.',
    };
    return m[code] ?? 'Error: $code';
  }
}
