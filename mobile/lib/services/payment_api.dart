import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Base URL of the trusted BeeWise backend (backend/ in this repository).
/// Supplied at build time: `--dart-define=BEEWISE_API_BASE_URL=https://...`.
const beeWiseApiBaseUrl = String.fromEnvironment('BEEWISE_API_BASE_URL');

class CheckoutSession {
  const CheckoutSession({
    required this.checkoutUrl,
    required this.orderCode,
    this.reused = false,
  });

  final Uri checkoutUrl;
  final int orderCode;
  final bool reused;
}

class PaymentStatusResult {
  const PaymentStatusResult({required this.invoiceStatus, this.classId});

  final String invoiceStatus;
  final String? classId;

  bool get verified => invoiceStatus == 'verified';
}

class PaymentApiException implements Exception {
  const PaymentApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Client for the trusted payment backend. It only *asks* the server to
/// create a payOS checkout or to re-check payOS; it never decides that an
/// invoice is paid. Verified state arrives through the Firestore invoice
/// stream, written by the server after it confirms the payment with payOS.
class PaymentApi {
  PaymentApi({
    required this._auth,
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.allowInsecureCheckout = false,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// EMULATOR demo builds only: accept the local http checkout page.
  final bool allowInsecureCheckout;

  bool get configured => _baseUrl.isNotEmpty;

  Future<CheckoutSession> createCheckout(String invoiceId) async {
    final body = await _post('/v1/payments/checkout', {'invoiceId': invoiceId});
    final url = Uri.tryParse(body['checkoutUrl'] as String? ?? '');
    final orderCode = body['orderCode'];
    // Only open payOS over HTTPS; anything else is treated as a bad response.
    final schemeOk =
        url?.scheme == 'https' ||
        (allowInsecureCheckout && url?.scheme == 'http');
    if (url == null || !schemeOk || orderCode is! int) {
      throw const PaymentApiException(
        'Máy chủ trả về liên kết thanh toán không hợp lệ.',
      );
    }
    return CheckoutSession(
      checkoutUrl: url,
      orderCode: orderCode,
      reused: body['reused'] == true,
    );
  }

  Future<PaymentStatusResult> reconcile(String invoiceId) async {
    final body = await _post('/v1/payments/reconcile', {
      'invoiceId': invoiceId,
    });
    return PaymentStatusResult(
      invoiceStatus: body['invoiceStatus'] as String? ?? 'pending',
      classId: body['classId'] as String?,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> payload,
  ) async {
    if (!configured) {
      throw const PaymentApiException(
        'Ứng dụng chưa được cấu hình máy chủ thanh toán.',
        code: 'not_configured',
      );
    }
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const PaymentApiException(
        'Bạn cần đăng nhập để thanh toán.',
        code: 'unauthenticated',
      );
    }
    final token = await user.getIdToken();
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const PaymentApiException(
        'Máy chủ thanh toán phản hồi quá lâu. Hãy thử lại.',
        code: 'timeout',
      );
    } on http.ClientException {
      throw const PaymentApiException(
        'Không kết nối được máy chủ thanh toán. Hãy kiểm tra mạng rồi thử lại.',
        code: 'network',
      );
    }
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body != null) {
      return body;
    }
    final error = body?['error'];
    final message = error is Map ? error['message'] : null;
    throw PaymentApiException(
      message is String && message.isNotEmpty
          ? message
          : 'Máy chủ thanh toán đang gặp sự cố. Hãy thử lại sau.',
      code: error is Map ? error['code'] as String? : null,
    );
  }
}
