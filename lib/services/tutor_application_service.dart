import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tutor_workspace_models.dart';
import 'tutor_application_api.dart';

class TutorApplicationService {
  TutorApplicationService(
    this._auth,
    this._firestore, {
    bool isResubmissionBackendAvailable = false,
    this._api,
  }) : _directResubmission = isResubmissionBackendAvailable;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final bool _directResubmission;
  final TutorApplicationApi? _api;

  /// `firebase/firestore.rules` forbids client updates of `tutorApplications`,
  /// so a `needs_info` resubmission is only possible through the trusted
  /// backend (`BEEWISE_API_BASE_URL`). Without it the UI keeps the submit
  /// button disabled instead of attempting a write that is certain to fail.
  bool get isResubmissionBackendAvailable =>
      _directResubmission || (_api?.configured ?? false);

  static const String resubmissionServerBlockMessage =
      'Chức năng gửi lại hồ sơ cần bổ sung hiện yêu cầu xác thực từ máy chủ '
      '(firestore.rules: tutorApplications.update = false). Hồ sơ gốc và lịch sử '
      'duyệt được giữ nguyên; vui lòng liên hệ BeeWise để mở khóa cập nhật.';

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

  /// Resubmits an existing `needs_info` tutor application without creating a
  /// new Firebase Auth user. Preserves the original UID and review history.
  Future<String> resubmit({
    required String uid,
    required String name,
    required String phone,
    required String qualification,
    required String introduction,
    required List<String> subjects,
    required List<String> grades,
    required int hourlyFee,
    required List<String> areas,
    required List<String> teachingModes,
    required String availability,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw const TutorApplicationException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    try {
      final docRef = _firestore.collection('tutorApplications').doc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw const TutorApplicationException('Không tìm thấy hồ sơ gia sư.');
      }

      final existing = TutorApplicationData.fromMap(uid, snapshot.data() ?? {});
      if (existing.status == 'rejected') {
        throw const TutorApplicationException(
          'Hồ sơ đã bị từ chối không thể tự gửi lại.',
        );
      }
      if (!existing.canEditApplication) {
        throw const TutorApplicationException(
          'Chỉ hồ sơ ở trạng thái cần bổ sung mới có thể cập nhật.',
        );
      }

      final api = _api;
      if (api != null && api.configured) {
        await api.resubmit(
          name: name,
          phone: phone,
          qualification: qualification,
          introduction: introduction,
          subjects: subjects,
          grades: grades,
          hourlyFee: hourlyFee,
          areas: areas,
          teachingModes: teachingModes,
          availability: availability,
        );
        await currentUser.updateDisplayName(name.trim());
        return uid;
      }

      if (!isResubmissionBackendAvailable) {
        throw const TutorApplicationException.ruleBlocked(
          resubmissionServerBlockMessage,
        );
      }

      await docRef.update({
        'name': name.trim(),
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
        if (existing.rejectionReason != null &&
            existing.rejectionReason!.trim().isNotEmpty)
          'previousRejectionReason': existing.rejectionReason!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await currentUser.updateDisplayName(name.trim());
      return uid;
    } on TutorApplicationException {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const TutorApplicationException.ruleBlocked(
          resubmissionServerBlockMessage,
        );
      }
      throw const TutorApplicationException(
        'Chưa cập nhật được hồ sơ. Kiểm tra mạng rồi thử lại.',
      );
    } catch (_) {
      throw const TutorApplicationException(
        'Chưa cập nhật được hồ sơ. Kiểm tra mạng rồi thử lại.',
      );
    }
  }

  /// Resolves the canonical role and authorization state for [uid] from the
  /// server-authoritative `tutorApplications/{uid}` document.
  Future<AccountRoleResolution> resolveAccountRole(String uid) async {
    final snapshot = await _firestore
        .collection('tutorApplications')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));

    if (!snapshot.exists) {
      return AccountRoleResolution(kind: AccountRoleKind.parent, uid: uid);
    }

    final data = TutorApplicationData.fromMap(uid, snapshot.data() ?? {});
    return AccountRoleResolution(
      kind: data.roleKind,
      uid: uid,
      application: data,
    );
  }

  Future<bool> hasApplication(String uid) async =>
      (await _firestore
              .collection('tutorApplications')
              .doc(uid)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15)))
          .exists;

  /// Live application status: updates as soon as staff change it in Firestore.
  Stream<String> watchStatus(String uid) => _firestore
      .collection('tutorApplications')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) throw const TutorApplicationException();
        return snapshot.data()?['status'] as String? ?? 'pending';
      });

  /// Live full application data for status, review, and tutor profile screens.
  Stream<TutorApplicationData?> watchApplicationData(String uid) => _firestore
      .collection('tutorApplications')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return TutorApplicationData.fromMap(uid, snapshot.data() ?? {});
      });

  Future<TutorApplicationData?> getApplicationData(String uid) async {
    final snapshot = await _firestore
        .collection('tutorApplications')
        .doc(uid)
        .get();
    if (!snapshot.exists) return null;
    return TutorApplicationData.fromMap(uid, snapshot.data() ?? {});
  }

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
  ]) : isBackendRuleBlocked = false;

  const TutorApplicationException.ruleBlocked(this.message)
    : isBackendRuleBlocked = true;

  final String message;
  final bool isBackendRuleBlocked;

  @override
  String toString() => message;
}

class TutorApplicationData {
  const TutorApplicationData({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.qualification,
    required this.introduction,
    required this.subjects,
    required this.grades,
    required this.hourlyFee,
    required this.areas,
    required this.teachingModes,
    required this.availability,
    required this.status,
    required this.verified,
    required this.active,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    this.previousRejectionReason,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String qualification;
  final String introduction;
  final List<String> subjects;
  final List<String> grades;
  final int hourlyFee;
  final List<String> areas;
  final List<String> teachingModes;
  final String availability;
  final String status;
  final bool verified;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;
  final String? previousRejectionReason;

  /// Only true when `status == 'approved' && verified == true && active == true`.
  bool get isAuthorizedTutor => status == 'approved' && verified && active;

  /// True when staff marked `status == 'approved'` but `verified` or `active`
  /// has not yet been activated.
  bool get isApprovedPendingActivation =>
      status == 'approved' && (!verified || !active);

  /// Only `needs_info` applications can be edited and resubmitted.
  bool get canEditApplication => status == 'needs_info';

  AccountRoleKind get roleKind {
    if (isAuthorizedTutor) return AccountRoleKind.authorizedTutor;
    if (isApprovedPendingActivation) {
      return AccountRoleKind.approvedPendingVerification;
    }
    return switch (status) {
      'needs_info' => AccountRoleKind.needsInfoApplicant,
      'rejected' => AccountRoleKind.rejectedApplicant,
      _ => AccountRoleKind.pendingApplicant,
    };
  }

  factory TutorApplicationData.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> toList(dynamic val) {
      if (val is Iterable) {
        return val.map((e) => e.toString()).toList(growable: false);
      }
      return const [];
    }

    return TutorApplicationData(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      qualification: map['qualification'] as String? ?? '',
      introduction: map['introduction'] as String? ?? '',
      subjects: toList(map['subjects']),
      grades: toList(map['grades']),
      hourlyFee: (map['hourlyFee'] as num?)?.round() ?? 0,
      areas: toList(map['areas']),
      teachingModes: toList(map['teachingModes']),
      availability: map['availability'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      verified: map['verified'] as bool? ?? false,
      active: map['active'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      rejectionReason:
          map['rejectionReason'] as String? ?? map['feedback'] as String?,
      previousRejectionReason: map['previousRejectionReason'] as String?,
    );
  }
}
