import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobx/mobx.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  _AuthStore({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  Future<bool> signInWithGoogle() async {
    if (isLoading) {
      return false;
    }

    isLoading = true;
    errorMessage = null;
    var signedIn = false;

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters(const {'prompt': 'select_account'});
        await _auth.signInWithPopup(provider);
        signedIn = true;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        signedIn = true;
      }
    } on FirebaseAuthException catch (error) {
      errorMessage = _mapFirebaseAuthError(error);
    } catch (_) {
      errorMessage =
          'Could not sign in with Google. Please check your connection and try again.';
    } finally {
      isLoading = false;
    }

    return signedIn;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method. Try that method instead.';
      case 'invalid-credential':
        return 'Received an invalid credential from Google. Please try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is disabled for this project.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Authentication failed. Please try again later.';
    }
  }
}
