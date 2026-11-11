import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

enum BeeWisePaymentMode { legacyPayOs, manualVietQr }

class BankRecipient {
  const BankRecipient(
    this.bankBin,
    this.accountNumber,
    this.accountHolder,
    this.instructions,
  );
  final String bankBin, accountNumber, accountHolder, instructions;

  static BankRecipient? parse(Object? raw) {
    if (raw is! Map) return null;
    final bin = raw['bankBin'];
    final account = raw['accountNumber'];
    final holder = raw['accountHolder'];
    final instructions = raw['instructions'];
    if (bin is! String ||
        !RegExp(r'^[0-9]{6}$').hasMatch(bin) ||
        account is! String ||
        !RegExp(r'^[A-Za-z0-9]{3,19}$').hasMatch(account) ||
        holder is! String ||
        holder.trim().length < 2 ||
        holder.length > 100 ||
        instructions is! String ||
        instructions.length > 300) {
      return null;
    }
    return BankRecipient(bin, account, holder, instructions);
  }

  Map<String, String> toMap() => {
    'bankBin': bankBin,
    'accountNumber': accountNumber,
    'accountHolder': accountHolder,
    'instructions': instructions,
  };
}

/// NAPAS QR Switching v1.5.2 sections 5.2.15 and 6.3.3.
/// The transfer reference is the bill number and purpose, so scanners
/// that map either additional field can carry the exact reference.
String dynamicVietQr({
  required BankRecipient recipient,
  required int amount,
  required String reference,
}) => napasAccountPayload(
  bankBin: recipient.bankBin,
  accountNumber: recipient.accountNumber,
  amount: amount,
  billNumber: reference,
  purpose: reference,
);

String napasAccountPayload({
  required String bankBin,
  required String accountNumber,
  required int amount,
  required String billNumber,
  required String purpose,
}) {
  final ascii = RegExp(r'^[ -~]{1,25}$');
  if (!RegExp(r'^[0-9]{6}$').hasMatch(bankBin) ||
      !RegExp(r'^[A-Za-z0-9]{3,19}$').hasMatch(accountNumber) ||
      amount < 1 ||
      amount > 100000000 ||
      !ascii.hasMatch(billNumber) ||
      !ascii.hasMatch(purpose)) {
    throw const FormatException('Invalid VietQR data');
  }
  String tlv(String id, String value) =>
      '$id${value.length.toString().padLeft(2, '0')}$value';
  final beneficiary = tlv('00', bankBin) + tlv('01', accountNumber);
  final payload = [
    tlv('00', '01'),
    tlv('01', '12'),
    tlv(
      '38',
      tlv('00', 'A000000727') + tlv('01', beneficiary) + tlv('02', 'QRIBFTTA'),
    ),
    tlv('53', '704'),
    tlv('54', amount.toString()),
    tlv('58', 'VN'),
    tlv('62', tlv('01', billNumber) + tlv('08', purpose)),
    '6304',
  ].join();
  var crc = 0xffff;
  for (final unit in payload.codeUnits) {
    crc ^= unit << 8;
    for (var bit = 0; bit < 8; bit++) {
      crc = ((crc << 1) ^ (crc & 0x8000 == 0 ? 0 : 0x1021)) & 0xffff;
    }
  }
  return '$payload${crc.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}

typedef PaymentRecord = DocumentSnapshot<Map<String, dynamic>>;

class ManualPayments {
  const ManualPayments(this.db);
  final FirebaseFirestore db;
  static const mode = 'manual_vietqr';
  static const chatStatus = 'final_waiting_class_offer';
  static final validId = RegExp(r'^[A-Za-z0-9]{20}$');

  CollectionReference<Map<String, dynamic>> get records =>
      db.collection('finalPayments');
  DocumentReference<Map<String, dynamic>> get recipient =>
      db.collection('settings').doc('paymentRecipient');
  static String classId(String id) => 'vietqr_$id';
  static String statusLabel(String status) => switch (status) {
    'offered' => 'Chờ phụ huynh xác nhận lớp',
    'awaiting_transfer' => 'Chờ chuyển khoản',
    'awaiting_verification' => 'Chờ nhân viên đối soát',
    'verified' => 'Đã xác minh',
    'rejected' => 'Yêu cầu bị từ chối',
    'cancelled' => 'Đã hủy',
    _ => 'Chưa có đề xuất lớp',
  };

  Future<void> issue({
    required String id,
    required String uid,
    required String subject,
    required String date,
    required String time,
    required String location,
    required int amount,
  }) {
    if (!validId.hasMatch(id)) {
      throw const FormatException('Mã cuộc trò chuyện không hợp lệ.');
    }
    final start = DateTime.tryParse(date);
    if (start == null || !start.toIso8601String().startsWith('${date}T')) {
      throw const FormatException('Nhập ngày theo định dạng YYYY-MM-DD.');
    }
    final random = Random.secure();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final reference =
        'BW${List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
    final payment = records.doc(id);
    final chat = db.collection('chats').doc(id);
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 5)),
    );
    return db.runTransaction((tx) async {
      final c = (await tx.get(chat)).data();
      final r = BankRecipient.parse((await tx.get(recipient)).data());
      final exists = (await tx.get(payment)).exists;
      if (r == null) {
        throw const FormatException(
          'Chưa có cấu hình tài khoản nhận VietQR hợp lệ.',
        );
      }
      if (c == null ||
          c['paymentMode'] != mode ||
          c['onboardingStatus'] != chatStatus ||
          exists) {
        throw const FormatException(
          'Cuộc trò chuyện không hợp lệ hoặc đã có đề xuất.',
        );
      }
      final tutorId = c['tutorId'] as String;
      final tutor = (await tx.get(db.collection('tutors').doc(tutorId))).data();
      final tutorName = tutor?['name'];
      if (tutorName is! String || tutor?['active'] != true) {
        throw const FormatException('Hồ sơ gia sư không còn công khai.');
      }
      tx.set(payment, {
        'invoiceId': id,
        'chatId': id,
        'parentId': c['parentId'],
        'tutorId': tutorId,
        'subject': subject.trim(),
        'tutorName': tutorName,
        'date': date,
        'time': time,
        'location': location.trim(),
        'amount': amount,
        'currency': 'VND',
        'recipient': r.toMap(),
        'transferReference': reference,
        'expiresAt': expiresAt,
        'createdAt': FieldValue.serverTimestamp(),
        'offeredBy': uid,
        'status': 'offered',
      });
      tx.set(db.collection('finalTransferReferences').doc(reference), {
        'invoiceId': id,
      });
    });
  }

  Future<void> parentAction({
    required String id,
    required String uid,
    required bool accept,
  }) {
    final payment = records.doc(id);
    final claim = payment.collection('reviews').doc().id;
    return db.runTransaction((tx) async {
      final data = (await tx.get(payment)).data();
      final status = data?['status'];
      if (data?['parentId'] != uid ||
          (accept
              ? status != 'offered'
              : !['awaiting_transfer', 'rejected'].contains(status))) {
        throw const FormatException('Hóa đơn không còn ở trạng thái phù hợp.');
      }
      tx.update(
        payment,
        accept
            ? {
                'status': 'awaiting_transfer',
                'acceptedAt': FieldValue.serverTimestamp(),
              }
            : {
                'status': 'awaiting_verification',
                'claimId': claim,
                'claimedAt': FieldValue.serverTimestamp(),
                'rejectedReason': FieldValue.delete(),
              },
      );
    });
  }

  Future<void> decide({
    required String id,
    required String uid,
    required String expectedClaim,
    required bool verify,
    String reason = '',
    String bankTransaction = '',
    int? matchedAmount,
    String matchedReference = '',
  }) {
    final payment = records.doc(id);
    final cleanBankTransaction = bankTransaction.trim().toUpperCase();
    return db.runTransaction((tx) async {
      final d = (await tx.get(payment)).data();
      if (d == null ||
          d['status'] != 'awaiting_verification' ||
          d['claimId'] != expectedClaim) {
        throw const FormatException(
          'Yêu cầu đã được xử lý hoặc thay đổi. Hãy mở lại.',
        );
      }
      final audit = <String, dynamic>{
        'invoiceId': id,
        'claimId': expectedClaim,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'status': verify ? 'verified' : 'rejected',
      };
      if (verify) {
        final recipient = BankRecipient.parse(d['recipient']);
        if (recipient == null ||
            matchedAmount != d['amount'] ||
            matchedReference != d['transferReference'] ||
            !RegExp(r'^[A-Z0-9]{6,40}$').hasMatch(cleanBankTransaction)) {
          throw const FormatException(
            'Đối chiếu lại số tiền, nội dung chuyển khoản và mã giao dịch ngân hàng.',
          );
        }
        final receipt = '${recipient.bankBin}_$cleanBankTransaction';
        tx.set(db.collection('finalBankReceipts').doc(receipt), {
          'invoiceId': id,
          'claimId': expectedClaim,
        });
        tx.set(db.collection('classes').doc(classId(id)), {
          'invoiceId': id,
          'chatId': id,
          'parentId': d['parentId'],
          'tutorId': d['tutorId'],
          for (final key in [
            'subject',
            'tutorName',
            'date',
            'time',
            'location',
          ])
            key: d[key],
          'paymentStatus': 'verified',
          'totalFee': d['amount'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(payment, {
          'status': 'verified',
          'verifiedBy': uid,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verificationMethod': 'manual_bank_transfer',
          'classId': classId(id),
        });
        audit.addAll({
          'bankReceiptId': receipt,
          'matchedAmount': matchedAmount,
          'matchedReference': matchedReference,
        });
      } else {
        final trimmed = reason.trim();
        if (trimmed.isEmpty || trimmed.length > 500) {
          throw const FormatException('Nhập lý do từ chối từ 1 đến 500 ký tự.');
        }
        tx.update(payment, {'status': 'rejected', 'rejectedReason': trimmed});
        audit['reason'] = trimmed;
      }
      tx.set(payment.collection('reviews').doc(expectedClaim), audit);
    });
  }

  Future<void> cancel(String id, String uid, String reason) =>
      records.doc(id).update({
        'status': 'cancelled',
        'cancelReason': reason.trim(),
        'cancelledBy': uid,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
}
