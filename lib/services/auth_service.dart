import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在ログイン中のユーザー
  User? get currentUser => _auth.currentUser;

  // ログイン状態の変化を監視するStream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 新規登録
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ログイン
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
