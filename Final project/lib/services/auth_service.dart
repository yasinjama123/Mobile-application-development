import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser        => _auth.currentUser;

  /// Register a regular user
  Future<UserCredential> signUpUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(displayName);
    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName,
      'email':       email,
      'role':        'user',
      'banned':      false,
      'reportCount': 0,
      'verifyCount': 0,
      'points':      0,
      'createdAt':   FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// Request admin registration — creates Auth user + pending Firestore doc
  Future<UserCredential> requestAdminAccount({
    required String email,
    required String password,
    required String displayName,
    required String reason,
    required String organization,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(displayName);

    // Create user doc with role = 'pending_admin'
    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName':  displayName,
      'email':        email,
      'role':         'pending_admin',
      'banned':       false,
      'reportCount':  0,
      'verifyCount':  0,
      'points':       0,
      'createdAt':    FieldValue.serverTimestamp(),
    });

    // Create admin_requests doc for review
    await _db.collection('admin_requests').doc(cred.user!.uid).set({
      'uid':          cred.user!.uid,
      'displayName':  displayName,
      'email':        email,
      'reason':       reason,
      'organization': organization,
      'status':       'pending',  // pending | approved | rejected
      'requestedAt':  FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Stream<AppUser?> appUserStream(String uid) => _db
      .collection('users').doc(uid).snapshots()
      .map((s) => s.exists ? AppUser.fromDoc(s) : null);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
