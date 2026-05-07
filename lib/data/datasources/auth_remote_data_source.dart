import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSource(this.firebaseAuth);
  // sign in
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Ném lỗi ra để BLoC bắt
      if (e.code == 'user-not-found') throw Exception('Email does not exist.');
      if (e.code == 'wrong-password') throw Exception('Incorrect password.');
      if (e.code == 'invalid-email') throw Exception('Invalid email format.');
      if (e.code == 'invalid-credential') throw Exception('Email hoặc mật khẩu không chính xác.');
      throw Exception(e.message ?? 'Login failed.');
    }
  }
  // sign up
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw Exception('Email already in use');
      if (e.code == 'invalid-email') throw Exception('Invalid email');
      if (e.code == 'weak-password') throw Exception('Password is too weak');
      throw Exception(e.message ?? 'Sign up failed');
    }
  }
}