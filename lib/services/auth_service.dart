import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AuthService {
  Stream<User?> authStateChanges();
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      await google.initialize();
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AuthFlowException('Google không trả về mã xác thực.');
      }
      final credential = GoogleAuthProvider.credential(idToken: token);
      final result = await _auth.signInWithCredential(credential);
      if (!await _isTutorApplicant(result.user)) await _saveParent(result.user);
      return result;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFlowException('Bạn đã hủy đăng nhập Google.');
      }
      throw AuthFlowException(
        'Không thể đăng nhập Google: ${error.description ?? error.code.name}',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_authMessage(error));
    }
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (!await _isTutorApplicant(result.user)) await _saveParent(result.user);
      return result;
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_authMessage(error));
    }
  }

  @override
  Future<UserCredential> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      UserCredential result;
      try {
        result = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        // Authenticate ownership before reconciling; never delete an identity.
        result = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final user = result.user!;
        if (await _isTutorApplicant(user) ||
            (await _firestore.collection('parents').doc(user.uid).get())
                .exists) {
          throw const AuthFlowException(
            'Email này đã có tài khoản. Hãy đăng nhập.',
          );
        }
      }
      await result.user?.updateDisplayName(name.trim());
      final uid = result.user?.uid;
      if (uid != null) {
        await _firestore.collection('parents').doc(uid).set({
          'displayName': name.trim(),
          'phone': phone.trim(),
          'email': email.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return result;
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_authMessage(error));
    } on FirebaseException {
      throw const AuthFlowException(
        'Tài khoản đã được tạo nhưng chưa lưu được hồ sơ. Hãy thử đăng ký lại với cùng email và mật khẩu, hoặc đăng nhập để khôi phục hồ sơ.',
      );
    }
  }

  Future<void> _saveParent(User? user) async {
    if (user == null) return;
    final parent = _firestore.collection('parents').doc(user.uid);
    final snapshot = await parent.get();
    final data = <String, Object?>{
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists) {
      data['displayName'] = user.displayName ?? '';
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await parent.set(data, SetOptions(merge: true));
  }

  Future<bool> _isTutorApplicant(User? user) async {
    if (user == null) return false;
    return (await _firestore
            .collection('tutorApplications')
            .doc(user.uid)
            .get())
        .exists;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Firebase sign-out must still complete when Google sign-out is offline.
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  String _authMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Địa chỉ email chưa đúng định dạng.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email hoặc mật khẩu chưa chính xác.',
    'email-already-in-use' => 'Email này đã có tài khoản. Hãy đăng nhập.',
    'weak-password' => 'Mật khẩu cần có ít nhất 8 ký tự và một chữ số.',
    'network-request-failed' =>
      'Mạng đang gián đoạn. Kiểm tra kết nối rồi thử lại.',
    'too-many-requests' => 'Bạn thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
    _ => 'Đăng nhập chưa thành công. Vui lòng thử lại.',
  };
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  Future<UserCredential> signInWithGoogle() => _unavailable();
  @override
  Future<UserCredential> signInWithEmail(String email, String password) =>
      _unavailable();
  @override
  Future<UserCredential> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _unavailable();
  @override
  Future<void> signOut() async =>
      throw const AuthFlowException('Firebase chưa được cấu hình.');
  Future<T> _unavailable<T>() async =>
      throw const AuthFlowException('Firebase chưa được cấu hình.');
}
