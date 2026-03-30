// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _auth  = FirebaseAuth.instance;
  final _gs    = GoogleSignIn();
  final _db    = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    final account = await _gs.signIn();
    if (account == null) return null;
    final gAuth = await account.authentication;
    final cred  = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken:     gAuth.idToken,
    );
    final result = await _auth.signInWithCredential(cred);
    await _upsertUser(result.user!);
    return result;
  }

  Future<void> _upsertUser(User u) async {
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(AppUser(
        uid: u.uid,
        name: u.displayName ?? 'Parent',
        email: u.email ?? '',
        photoUrl: u.photoURL,
        createdAt: DateTime.now(),
      ).toMap());
    } else {
      await ref.update({'photoUrl': u.photoURL, 'lastLogin': Timestamp.now()});
    }
  }

  Future<AppUser?> fetchCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _db.collection('users').doc(u.uid).get();
    return doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null;
  }

  Future<void> signOut() async {
    await _gs.signOut();
    await _auth.signOut();
  }
}