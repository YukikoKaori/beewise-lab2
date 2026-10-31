import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorApplicationService {
  TutorApplicationService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<String> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String qualification,
    required String introduction,
    required List<String> subjects,
    required List<String> grades,
    required int hourlyFee,
    required List<String> areas,
    required List<String> teachingModes,
    required String availability,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const TutorApplicationException();
      await user.updateDisplayName(name.trim());
      await _firestore.collection('tutorApplications').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'qualification': qualification.trim(),
        'introduction': introduction.trim(),
        'subjects': subjects,
        'grades': grades,
        'hourlyFee': hourlyFee,
        'areas': areas,
        'teachingModes': teachingModes,
        'availability': availability.trim(),
        'status': 'pending',
        'verified': false,
        'active': false,
        'consentAccepted': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return user.uid;
    } catch (error) {
      final user = credential?.user;
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      if (error is TutorApplicationException) rethrow;
      if (error is FirebaseAuthException) {
        throw TutorApplicationException(_authMessage(error));
      }
      throw const TutorApplicationException(
        'Chưa gửi được hồ sơ. Kiểm tra mạng rồi thử lại.',
      );
    }
  }

  Future<bool> hasApplication(String uid) async =>
      (await _firestore
              .collection('tutorApplications')
              .doc(uid)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15)))
          .exists;

  Future<String> status(String uid) async {
    final snapshot = await _firestore
        .collection('tutorApplications')
        .doc(uid)
        .get();
    if (!snapshot.exists) throw const TutorApplicationException();
    return snapshot.data()?['status'] as String? ?? 'pending';
  }

  String _authMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Địa chỉ email chưa đúng định dạng.',
    'email-already-in-use' => 'Email này đã có tài khoản. Hãy đăng nhập.',
    'weak-password' => 'Mật khẩu cần có ít nhất 8 ký tự và một chữ số.',
    'network-request-failed' =>
      'Mạng đang gián đoạn. Kiểm tra kết nối rồi thử lại.',
    'too-many-requests' => 'Bạn thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
    _ => 'Chưa tạo được tài khoản. Vui lòng thử lại.',
  };
}

class TutorApplicationException implements Exception {
  const TutorApplicationException([
    this.message = 'Không tìm thấy hồ sơ gia sư.',
  ]);

  final String message;

  @override
  String toString() => message;
}
