import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Provides all Firebase Authentication operations for the app.
///
/// All Firebase calls live here — no auth logic touches widgets.
/// Friendly, short error messages are returned via [AuthException].
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId:
                  '239331962352-sa70glmurk76psqa0umdoql5s095em66.apps.googleusercontent.com',
            );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // ── Auth state ─────────────────────────────────────────────────────────────

  /// Stream that emits the current [User] or `null` when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  /// Returns true if the current user signed in only with Google
  /// (has no password / email provider).
  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com') &&
        !user.providerData.any((p) => p.providerId == 'password');
  }

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

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Signs in (or registers) with Google.
  ///
  /// Returns the [User] on success, or `null` if the user cancelled the picker.
  /// Throws [AuthException] on any real error.
  ///
  /// On first sign-in, creates the Firestore user doc and seeds categories
  /// via [onNewUser] callback — the caller (widget) supplies this so the
  /// service stays free of CategoryRepository.
  Future<User?> signInWithGoogle({
    required Future<void> Function(User user) onNewUser,
  }) async {
    try {
      // Show the account picker.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user dismissed the picker

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Check if this is a brand-new Firestore user.
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // First Google sign-in — create the user doc.
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? googleUser.displayName ?? '',
          'email': user.email ?? googleUser.email,
          'currencyCode': 'BDT',
          'joinedAt': FieldValue.serverTimestamp(),
        });
        // Seed default categories (callback provided by caller).
        await onNewUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw const AuthException(
            'No internet connection. Please check your network.');
      }
      throw const AuthException('Something went wrong. Please try again.');
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

  /// Re-authenticates with email [password] (for password users) or
  /// re-authenticates via Google (for Google-only users), then deletes the
  /// Firebase Auth user.
  ///
  /// **Note**: Call [UserRepository.deleteUserData] before this.
  ///
  /// Throws [AuthException] on failure.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user found.');
    }
    try {
      if (isGoogleUser) {
        // Re-authenticate via Google.
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException('Re-authentication cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        if (password == null || user.email == null) {
          throw const AuthException('No signed-in user found.');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.delete();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    } catch (_) {
      throw AuthException('Could not delete account. Please try again.');
    }
  }

  // ── Sign-out ───────────────────────────────────────────────────────────────

  /// Signs the current user out of both Google and Firebase.
  Future<void> signOut() async {
    // signOut of GoogleSignIn is best-effort — ignore any error.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'sign-in-cancelled':
      case 'canceled':
        return '';
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
