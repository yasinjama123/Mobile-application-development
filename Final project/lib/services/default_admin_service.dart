import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DefaultAdminService {
  static const String _defaultEmail = 'admin@fairprice.et';
  static const String _defaultPassword = 'Admin@FairPrice2025';
  static const String _defaultName = 'Super Admin';

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call this once from AppProvider before listening to auth changes.
  static Future<void> ensureDefaultAdmin() async {
    try {
      // ── Check the sentinel doc first (fast path) ──────────────────────
      final config =
          await _db.collection('platform_config').doc('default_admin').get();

      if (config.exists) {
        debugPrint('DefaultAdmin: already seeded — skipping.');
        return;
      }

      debugPrint('DefaultAdmin: no seed found — creating default admin…');

      // ── Try to sign in (account may already exist in Auth) ────────────
      String? uid;
      try {
        final cred = await _auth.signInWithEmailAndPassword(
            email: _defaultEmail, password: _defaultPassword);
        uid = cred.user!.uid;
        debugPrint('DefaultAdmin: Auth account already existed.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Create it
          final cred = await _auth.createUserWithEmailAndPassword(
              email: _defaultEmail, password: _defaultPassword);
          await cred.user!.updateDisplayName(_defaultName);
          uid = cred.user!.uid;
          debugPrint('DefaultAdmin: Auth account created. UID=$uid');
        } else {
          debugPrint('DefaultAdmin: Auth error — ${e.code}: ${e.message}');
          return;
        }
      }

      // ── Write / overwrite the Firestore user doc ───────────────────────
      await _db.collection('users').doc(uid).set({
        'displayName': _defaultName,
        'email': _defaultEmail,
        'role': 'admin',
        'banned': false,
        'reportCount': 0,
        'verifyCount': 0,
        'points': 0,
        'photoUrl': null,
        'location': 'Addis Ababa, Ethiopia',
        'createdAt': FieldValue.serverTimestamp(),
        'isSuperAdmin': true, // extra flag for the very first admin
      }, SetOptions(merge: true));

      // ── Write sentinel so we never re-run this ─────────────────────────
      await _db.collection('platform_config').doc('default_admin').set({
        'uid': uid,
        'email': _defaultEmail,
        'seededAt': FieldValue.serverTimestamp(),
        'note':
            'Default super-admin. Change password immediately after first login.',
      });

      debugPrint('DefaultAdmin: ✅ Default admin ready. '
          'Email=$_defaultEmail  Password=$_defaultPassword');

      // Sign out so the regular auth flow takes over
      await _auth.signOut();
    } catch (e) {
      debugPrint('DefaultAdmin: Unexpected error — $e');
    }
  }
}
