import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provides all Firebase Authentication operations for the app.
///
/// All Firebase calls live here — no auth logic touches widgets.
/// Friendly, short error messages are returned via [AuthException].
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── Auth state ─────────────────────────────────────────────────────────────

  /// Stream that emits the current [User] or `null` when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  // ── Registration ───────────────────────────────────────────────────────────

  /// Creates a new user with [email] and [password], updates their
  /// [displayName] to [name], and writes the Firestore user document.
  ///
  /// Throws [AuthException] on failure.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      // Set display name in Firebase Auth profile.
      await user.updateDisplayName(name);

      // Create Firestore user document.
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'currencyCode': 'BDT',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  // ── Sign-in ────────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  ///
  /// Throws [AuthException] on failure.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  // ── Password reset ─────────────────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  ///
  /// Throws [AuthException] on failure.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Could not send reset email. Please try again.');
    }
  }

  // ── Change password ────────────────────────────────────────────────────────

  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  ///
  /// Throws [AuthException] on any failure with a friendly message.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No signed-in user found.');
    }
    try {
      // Re-authenticate first (required by Firebase before sensitive ops).
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Could not change password. Please try again.');
    }
  }

  // ── Delete account ─────────────────────────────────────────────────────────

  /// Re-authenticates with [password], then deletes the Firebase Auth user.
  ///
  /// **Note**: Call [UserRepository.deleteUserData] before this to remove
  /// Firestore data, so security rules don't block the delete after sign-out.
  ///
  /// Throws [AuthException] on failure.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No signed-in user found.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Could not delete account. Please try again.');
    }
  }

  // ── Sign-out ───────────────────────────────────────────────────────────────

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  static String _mapCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'Please log out and log back in, then try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// ── AuthException ─────────────────────────────────────────────────────────────

/// Carries a user-friendly error message from [AuthService].
class AuthException implements Exception {
  const AuthException(this.message);

  /// Short, human-readable error message safe to display in the UI.
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
