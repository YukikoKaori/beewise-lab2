import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'payment_api.dart' show beeWiseApiBaseUrl;
import 'tutor_application_service.dart' show TutorApplicationException;

/// Client for the trusted backend's tutor-application endpoint.
///
/// A `needs_info` application cannot be updated by the client (Firestore rules
/// forbid it by design), so the applicant asks the server to apply the edit.
/// The server derives the applicant from the ID token, validates every field,
/// and moves the application back to `pending`; it never trusts a client-sent
/// UID, email or status.
class TutorApplicationApi {
  TutorApplicationApi({
    required this._auth,
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUrl = (baseUrl ?? beeWiseApiBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       ),
       _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  bool get configured => _baseUrl.isNotEmpty;

  Future<void> resubmit({
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
    if (!configured) {
      throw const TutorApplicationException(
        'Ứng dụng chưa được cấu hình máy chủ BeeWise.',
      );
    }
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const TutorApplicationException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final token = await user.getIdToken();
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/tutor-applications/resubmit'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode({
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
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const TutorApplicationException(
        'Máy chủ phản hồi quá lâu. Hãy thử lại.',
      );
    } on http.ClientException {
      throw const TutorApplicationException(
        'Không kết nối được máy chủ. Hãy kiểm tra mạng rồi thử lại.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String? message;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final error = decoded is Map ? decoded['error'] : null;
      if (error is Map && error['message'] is String) {
        message = error['message'] as String;
      }
    } on FormatException {
      message = null;
    }
    throw TutorApplicationException(
      message != null && message.isNotEmpty
          ? message
          : 'Máy chủ đang gặp sự cố. Hãy thử lại sau.',
    );
  }
}
