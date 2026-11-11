import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/tutor.dart';
import 'report_data.dart';

export 'report_data.dart' show ExportException;

class ExportedReport {
  const ExportedReport({
    required this.file,
    required this.sizeBytes,
    this.localReportId,
  });
  final File file;
  final int sizeBytes;
  final String? localReportId;
}

class SavedReport {
  const SavedReport({
    required this.reportId,
    required this.documentPath,
    this.localOnly = false,
    this.tutorId,
    required this.sizeBytes,
  });
  final String reportId;
  final String documentPath;
  final bool localOnly;
  final String? tutorId;
  final int sizeBytes;
}

/// Cancellation stops exposure/transaction retries, not an already committed
/// server write. Such a write remains private to its original owner.
class ReportOperation {
  bool cancelled = false;
  void cancel() => cancelled = true;
  void check() {
    if (cancelled) throw const ExportException('Thao tác đã hủy.');
  }
}

class ExportService {
  ExportService(
    this._firestore,
    this._auth, {
    this.timeout = const Duration(seconds: 30),
    this.localMetadataOnly = false,
  });
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final Duration timeout;
  final bool localMetadataOnly;
  static const _pdfChannel = MethodChannel('beewise/local_pdf');
  static final _idPattern = RegExp(r'^[A-Za-z0-9]{20}$');

  Stream<String?> get ownerChanges =>
      _auth?.authStateChanges().map(
        (user) => user != null && !user.isAnonymous ? user.uid : null,
      ) ??
      const Stream<String?>.empty();

  String? get currentOwnerUid {
    final user = _auth?.currentUser;
    return user != null && !user.isAnonymous ? user.uid : null;
  }

  Future<ExportedReport> buildTutorSummary(Tutor tutor) async {
    final fontData = await rootBundle.load(
      'assets/fonts/BeVietnamPro-Regular.ttf',
    );
    final boldData = await rootBundle.load(
      'assets/fonts/BeVietnamPro-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final bold = pw.Font.ttf(boldData);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'BeeWise - Thông tin gia sư',
            style: pw.TextStyle(font: bold, fontSize: 22),
          ),
          pw.SizedBox(height: 16),
          pw.Text(tutor.name, style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 8),
          if (tutor.isDemoProfile) ...[
            pw.Text(Tutor.demoDisclosure, style: pw.TextStyle(font: bold)),
            pw.Text(Tutor.demoDisclaimer, style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 8),
          ],
          _row('Chuyên môn', tutor.subjects.join(', '), font, bold),
          _row('Lớp', tutor.grades.join(', '), font, bold),
          _row('Học phí', '${tutor.hourlyFee}đ/giờ', font, bold),
          _row('Khu vực', tutor.areas.join(', '), font, bold),
          _row('Hình thức', tutor.teachingModes.join(', '), font, bold),
          _row('Lịch rảnh', tutor.availability, font, bold),
          _row('Kinh nghiệm', '${tutor.experienceYears} năm', font, bold),
          _row(
            'Xác minh',
            tutor.isDemoProfile
                ? Tutor.demoDisclosure
                : tutor.verified
                ? 'Đã xác minh'
                : 'Chưa xác minh',
            font,
            bold,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            tutor.introduction,
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thông tin được lấy từ hồ sơ gia sư BeeWise tại thời điểm xuất.',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
    final bytes = await document.save();
    final directory = await getTemporaryDirectory();
    final target = await Directory(directory.path)
        .createTemp('beewise-export-');
    final file = File('${target.path}/beewise-tutor-${tutor.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return ExportedReport(
      file: file,
      sizeBytes: bytes.length,
      localReportId: localMetadataOnly
          ? _firestore?.collection('reports').doc().id
          : null,
    );
  }

  pw.Widget _row(String label, String value, pw.Font regular, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 115,
              child: pw.Text(
                label,
                style: pw.TextStyle(font: bold, fontSize: 11),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? 'Chưa có thông tin' : value,
                style: pw.TextStyle(font: regular, fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Future<T> _owned<T>(
    ReportOperation operation,
    Future<T> Function(String uid, void Function() check) action,
  ) async {
    final uid = currentOwnerUid;
    if (uid == null || _firestore == null) {
      throw const ExportException('Đăng nhập để lưu và tải báo cáo riêng.');
    }
    void check() {
      operation.check();
      if (currentOwnerUid != uid) {
        operation.cancel();
        throw const ExportException('Tài khoản đã thay đổi. Hãy thử lại.');
      }
    }

    final subscription = _auth!.authStateChanges().listen((user) {
      if (user == null || user.isAnonymous || user.uid != uid) {
        operation.cancel();
      }
    }, onError: (Object error, StackTrace stack) => operation.cancel());
    try {
      check();
      final result = await action(uid, check).timeout(timeout);
      check();
      return result;
    } on TimeoutException {
      operation.cancel();
      throw const ExportException(
        'Chưa xác nhận được từ server. Hãy kiểm tra mạng và thử lại.',
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<SavedReport> saveReport({
    required String tutorId,
    required ExportedReport report,
    required ReportOperation operation,
    void Function()? onSaving,
  }) => _owned(operation, (uid, check) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(tutorId)) {
      throw const ExportException('Mã hồ sơ không hợp lệ.');
    }
    if (report.sizeBytes < 5 ||
        report.sizeBytes > ReportData.maxPdfBytes ||
        await report.file.length() > ReportData.maxPdfBytes) {
      throw const ExportException('PDF không hợp lệ hoặc lớn hơn 500 KiB.');
    }
    check();
    final bytes = await report.file.readAsBytes();
    check();
    if (bytes.length != report.sizeBytes) {
      throw const ExportException('PDF đã thay đổi. Hãy xuất lại.');
    }
    if (localMetadataOnly) {
      return _saveLocal(
        uid,
        tutorId,
        report.localReportId,
        bytes,
        check,
        onSaving,
      );
    }
    final encoded = ReportData.encode(bytes);
    final document = _firestore!
        .collection('reports')
        .doc(uid)
        .collection('files')
        .doc();
    final data = <String, dynamic>{
      'ownerUid': uid,
      'reportId': document.id,
      'tutorId': tutorId,
      'fileName': 'beewise-tutor-$tutorId.pdf',
      'contentType': ReportData.contentType,
      'encoding': 'base64',
      'sizeBytes': bytes.length,
      'base64Data': encoded,
    };
    if (ReportData.estimatedDocumentBytes(data, document.path) >
        ReportData.maxEstimatedDocumentBytes) {
      throw const ExportException('Báo cáo vượt giới hạn document.');
    }
    onSaving?.call();
    // Transactions fail offline rather than enqueueing a local cache write.
    // The read/existence check plus create-only rules prevent overwrite.
    await _firestore.runTransaction<void>(
      (transaction) async {
        check();
        final existing = await transaction.get(document);
        final tutor = await transaction.get(
          _firestore.collection('tutors').doc(tutorId),
        );
        check();
        final raw = tutor.data();
        if (raw == null) throw const ExportException('Không tìm thấy gia sư.');
        final profile = Tutor.fromMap(tutorId, raw);
        if (!profile.reportEligible) {
          throw const ExportException(
            'Chỉ lưu cloud từ hồ sơ gia sư đã xác minh, không phải dữ liệu thử.',
          );
        }
        if (existing.exists) {
          throw const ExportException('Mã báo cáo đã tồn tại. Hãy thử lại.');
        }
        transaction.set(document, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      },
      timeout: timeout,
      maxAttempts: 2,
    );
    check();
    final stored = await document.get(const GetOptions(source: Source.server));
    check();
    final value = _validateDocument(stored, uid, document.id);
    final downloaded = ReportData.decode(value);
    if (downloaded.length != bytes.length || value['base64Data'] != encoded) {
      throw const ExportException('Server chưa trả đúng nội dung PDF.');
    }
    return SavedReport(
      reportId: document.id,
      documentPath: document.path,
      sizeBytes: bytes.length,
    );
  });

  CollectionReference<Map<String, dynamic>> _reports(String uid, bool local) =>
      _firestore!
          .collection('reports')
          .doc(uid)
          .collection(local ? 'localFiles' : 'files');

  Future<File> _localFile(String uid, String id) async {
    if (!_idPattern.hasMatch(id)) {
      throw const ExportException('Mã báo cáo không hợp lệ.');
    }
    final directory = await getApplicationSupportDirectory();
    final scope = base64Url.encode(utf8.encode(uid)).replaceAll('=', '');
    return File(
      '${directory.path}/local-reports/$scope/beewise-report-$id.pdf',
    );
  }

  Future<SavedReport> _saveLocal(
    String uid,
    String tutorId,
    String? id,
    List<int> bytes,
    void Function() check,
    void Function()? onSaving,
  ) async {
    if (id == null) throw const ExportException('Hãy xuất lại PDF để lưu.');
    ReportData.validatePdf(bytes);
    final document = _reports(uid, true).doc(id);
    final file = await _localFile(uid, id);
    check();
    try {
      await file.parent.create(recursive: true);
      check();
      // A complete file is published atomically, even if the process stops
      // mid-write. The stable ID makes retries use the same metadata record.
      final temp = File('${file.path}.pending');
      await temp.writeAsBytes(bytes, flush: true);
      check();
      await temp.rename(file.path);
      check();
    } on FileSystemException {
      throw const ExportException('Không thể lưu PDF trên thiết bị.');
    }
    final data = <String, dynamic>{
      'ownerUid': uid,
      'reportId': id,
      'tutorId': tutorId,
      'fileName': 'beewise-report-$id.pdf',
      'contentType': ReportData.contentType,
      'sizeBytes': bytes.length,
    };
    onSaving?.call();
    await _firestore!.runTransaction<void>(
      (tx) async {
        check();
        final existing = await tx.get(document);
        check();
        if (!existing.exists) {
          tx.set(document, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      },
      timeout: timeout,
      maxAttempts: 2,
    );
    check();
    final stored = await document.get(const GetOptions(source: Source.server));
    check();
    final confirmed = _validateDocument(stored, uid, id);
    if (confirmed.containsKey('base64Data') ||
        data.entries.any((entry) => confirmed[entry.key] != entry.value)) {
      throw const ExportException('Server chưa xác nhận đúng thông tin PDF.');
    }
    return SavedReport(
      reportId: id,
      documentPath: document.path,
      sizeBytes: bytes.length,
      localOnly: true,
      tutorId: tutorId,
    );
  }

  /// Restore recent Final and legacy records without migrating legacy bytes.
  Future<List<SavedReport>> recentReports(ReportOperation operation) => _owned(
    operation,
    (uid, check) async {
      final sources = await Future.wait([
        for (final local in [true, false])
          _reports(uid, local)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get(const GetOptions(source: Source.server)),
      ]);
      check();
      final items = <(Timestamp, SavedReport)>[];
      for (var i = 0; i < sources.length; i++) {
        for (final doc in sources[i].docs) {
          final data = _validateDocument(doc, uid, doc.id);
          if (data['sizeBytes'] is! int || data['tutorId'] is! String) continue;
          items.add((
            data['createdAt'] as Timestamp,
            SavedReport(
              reportId: doc.id,
              documentPath: doc.reference.path,
              sizeBytes: data['sizeBytes'] as int,
              localOnly: i == 0,
              tutorId: data['tutorId'] as String,
            ),
          ));
        }
      }
      items.sort((a, b) => b.$1.compareTo(a.$1));
      return items.map((item) => item.$2).toList();
    },
  );

  Future<File> resolveLocalReport(
    SavedReport report,
    ReportOperation operation,
  ) => _owned(operation, (uid, check) async {
    if (!report.localOnly ||
        report.documentPath != _reports(uid, true).doc(report.reportId).path) {
      throw const ExportException('Báo cáo không thuộc tài khoản hiện tại.');
    }
    final file = await _localFile(uid, report.reportId);
    check();
    try {
      if (!await file.exists()) {
        throw const ExportException(
          'Không tìm thấy PDF trên thiết bị này. Hãy xuất lại từ hồ sơ gia sư.',
        );
      }
      final length = await file.length();
      if (length != report.sizeBytes || length > ReportData.maxPdfBytes) {
        throw const ExportException(
          'PDF trên thiết bị không hợp lệ. Hãy xuất lại.',
        );
      }
      ReportData.validatePdf(await file.readAsBytes());
    } on FileSystemException {
      throw const ExportException('Không thể đọc PDF trên thiết bị.');
    }
    check();
    return file;
  });

  Future<void> openLocalReport(
    SavedReport report,
    ReportOperation operation,
  ) async {
    final uid = currentOwnerUid;
    final file = await resolveLocalReport(report, operation);
    operation.check();
    if (currentOwnerUid != uid) {
      throw const ExportException('Tài khoản đã thay đổi. Hãy thử lại.');
    }
    try {
      await _pdfChannel.invokeMethod<void>('open', file.path);
    } on PlatformException catch (error) {
      throw ExportException(
        error.code == 'no_viewer'
            ? 'Máy chưa có ứng dụng đọc PDF. Bạn vẫn có thể chia sẻ tệp.'
            : 'Không thể mở PDF trên thiết bị.',
      );
    } on MissingPluginException {
      throw const ExportException(
        'Thiết bị này không hỗ trợ mở PDF từ BeeWise.',
      );
    }
  }

  Map<String, dynamic> _validateDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String uid,
    String id,
  ) {
    final data = snapshot.data();
    if (!snapshot.exists ||
        snapshot.metadata.isFromCache ||
        snapshot.metadata.hasPendingWrites ||
        data == null ||
        data['ownerUid'] != uid ||
        data['reportId'] != id ||
        data['createdAt'] is! Timestamp) {
      throw const ExportException('Chưa có báo cáo được server xác nhận.');
    }
    return data;
  }

  Future<Map<String, dynamic>> getReport(
    String reportId, {
    required ReportOperation operation,
  }) => _owned(operation, (uid, check) async {
    if (!RegExp(r'^[A-Za-z0-9]{20}$').hasMatch(reportId)) {
      throw const ExportException('Mã báo cáo không hợp lệ.');
    }
    final snapshot = await _firestore!
        .collection('reports')
        .doc(uid)
        .collection('files')
        .doc(reportId)
        .get(const GetOptions(source: Source.server));
    check();
    final data = _validateDocument(snapshot, uid, reportId);
    ReportData.decode(data);
    return data;
  });

  Future<File> downloadReport(
    String reportId, {
    required ReportOperation operation,
  }) => _owned(operation, (uid, check) async {
    final data = await getReport(reportId, operation: operation);
    check();
    final bytes = ReportData.decode(data);
    final directory = await getTemporaryDirectory();
    check();
    // A unique private temporary directory avoids cross-account path reuse.
    final target = await Directory(directory.path)
        .createTemp('beewise-report-');
    final file = await File('${target.path}/report.pdf')
        .writeAsBytes(bytes, flush: true);
    check();
    return file;
  });
}
