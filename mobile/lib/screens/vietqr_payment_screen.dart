import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';

import '../viewmodels/app_providers.dart';
import '../widgets/bee_wise_widgets.dart';

final _manualPayment = StreamProvider.autoDispose
    .family<PaymentRecord, (String, String)>(
      (ref, key) =>
          ManualPayments(FirebaseFirestore.instance).records
              .doc(key.$2)
              .snapshots(includeMetadataChanges: true),
    );

class VietQrPaymentScreen extends ConsumerStatefulWidget {
  const VietQrPaymentScreen({super.key, required this.chatId});
  final String chatId;
  @override
  ConsumerState<VietQrPaymentScreen> createState() =>
      _VietQrPaymentScreenState();
}

class _VietQrPaymentScreenState extends ConsumerState<VietQrPaymentScreen> {
  bool _working = false;
  String? _error;

  Future<void> _submit(String uid, bool accept) async {
    if (_working || FirebaseAuth.instance.currentUser?.uid != uid) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ManualPayments(FirebaseFirestore.instance)
          .parentAction(id: widget.chatId, uid: uid, accept: accept);
    } catch (error) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Chưa xác nhận được. Kiểm tra kết nối và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentAuthenticatedUidProvider);
    final enabled =
        ref.watch(paymentModeProvider) == BeeWisePaymentMode.manualVietQr;
    if (!enabled ||
        uid == null ||
        !ref.watch(firebaseReadyProvider) ||
        !ManualPayments.validId.hasMatch(widget.chatId)) {
      return const BeeWiseScaffold(
        title: 'Thanh toán VietQR',
        showBack: true,
        body: Center(
          child: Text('Không thể mở thanh toán VietQR cho tài khoản này.'),
        ),
      );
    }
    final provider = _manualPayment((uid, widget.chatId));
    return BeeWiseScaffold(
      title: 'Đề xuất lớp và VietQR',
      showBack: true,
      body: ref
          .watch(provider)
          .when(
            loading: () => const LoadingStateView(),
            error: (_, _) => ErrorStateView(
              message: 'Không thể tải đề xuất hoặc tài khoản không có quyền.',
              onRetry: () => ref.invalidate(provider),
            ),
            data: (record) {
              final d = record.data();
              final server =
                  !record.metadata.isFromCache &&
                  !record.metadata.hasPendingWrites;
              if (d == null) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Chưa có đề xuất lớp Final. Gửi mã cuộc trò chuyện cho nhân viên BeeWise để họ chuẩn bị đề xuất.',
                    ),
                    _CopyLine('Mã cuộc trò chuyện', widget.chatId),
                    if (!server) const Text('Đang chờ xác nhận từ máy chủ.'),
                  ],
                );
              }
              if (d['parentId'] != uid) {
                return const Center(
                  child: Text('Đề xuất không thuộc tài khoản hiện tại.'),
                );
              }
              final status = d['status'] as String? ?? '';
              final expiry = d['expiresAt'];
              final expired =
                  expiry is! Timestamp ||
                  !expiry.toDate().isAfter(DateTime.now());
              final pending =
                  status == 'offered' ||
                  status == 'awaiting_transfer' ||
                  status == 'rejected';
              final recipient = BankRecipient.parse(d['recipient']);
              final amount = d['amount'];
              final reference = d['transferReference'];
              final configured =
                  recipient != null &&
                  amount is int &&
                  amount > 0 &&
                  amount <= 100000000 &&
                  reference is String &&
                  RegExp(r'^BW[A-Z0-9]{16}$').hasMatch(reference);
              final visibleQr =
                  configured &&
                  status == 'awaiting_transfer' &&
                  server &&
                  !expired;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    ManualPayments.statusLabel(status),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (!server)
                    const Text(
                      'Đang chờ Firestore xác nhận. Không chuyển tiền dựa trên dữ liệu lưu tạm.',
                    ),
                  const SizedBox(height: 10),
                  Text('${d['subject']} · ${d['tutorName']}'),
                  Text('${d['date']} · ${d['time']} · ${d['location']}'),
                  if (amount is int)
                    _CopyLine(
                      'Số tiền VND',
                      amount.toString(),
                      display:
                          '${NumberFormat.decimalPattern('vi_VN').format(amount)} ₫',
                    ),
                  _CopyLine('Mã hóa đơn', widget.chatId),
                  if (!configured && pending)
                    const Text(
                      'Chưa có cấu hình tài khoản nhận hợp lệ. Vui lòng liên hệ BeeWise.',
                    ),
                  if (expired && pending)
                    const Text(
                      'Đã hết hạn. Không chuyển thêm tiền; liên hệ BeeWise nếu đã chuyển.',
                    ),
                  if (status == 'cancelled')
                    Text('${d['cancelReason'] ?? 'Đề xuất đã hủy.'}'),
                  if (status == 'rejected') ...[
                    Text(
                      '${d['rejectedReason'] ?? 'Nhân viên chưa tìm thấy giao dịch khớp.'}',
                    ),
                    const Text(
                      'Nếu giao dịch cũ đã xuất hiện, có thể gửi lại yêu cầu. Không chuyển lần nữa chỉ vì bị từ chối.',
                    ),
                  ],
                  if (visibleQr) ...[
                    Center(
                      child: Semantics(
                        label: 'Mã QR VietQR của hóa đơn',
                        image: true,
                        child: SizedBox.square(
                          dimension: 232,
                          child: CustomPaint(
                            painter: _QrPainter(
                              dynamicVietQr(
                                recipient: recipient,
                                amount: amount,
                                reference: reference,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _CopyLine('Ngân hàng (BIN)', recipient.bankBin),
                    _CopyLine('Chủ tài khoản', recipient.accountHolder),
                    _CopyLine('Số tài khoản', recipient.accountNumber),
                    _CopyLine('Nội dung chuyển khoản', reference),
                    if (recipient.instructions.isNotEmpty)
                      Text(recipient.instructions),
                    const Text(
                      'Chỉ chuyển đến tài khoản hiển thị, đúng số tiền và nguyên nội dung. Nhân viên đối chiếu giao dịch ngân hàng; xác minh không diễn ra tự động.',
                    ),
                  ],
                  if (status == 'awaiting_verification')
                    const Text(
                      'Bạn đã báo chuyển khoản. Lịch học chỉ mở sau khi nhân viên kiểm tra khoản tiền thực nhận.',
                    ),
                  if (status == 'verified' &&
                      server &&
                      d['classId'] == ManualPayments.classId(widget.chatId))
                    BeeWiseButton(
                      label: 'Xem lịch học chính thức',
                      onPressed: () =>
                          context.push('/schedule/${d['classId']}'),
                    ),
                  const SizedBox(height: 12),
                  if (_error != null) ErrorStateView(message: _error!),
                  if (server && pending && !expired && configured)
                    BeeWiseButton(
                      label: switch (status) {
                        'offered' => 'Xác nhận đề xuất lớp',
                        'rejected' => 'Gửi lại yêu cầu đối soát',
                        _ => 'Tôi đã chuyển khoản',
                      },
                      loading: _working,
                      onPressed: _working
                          ? null
                          : () => _submit(uid, status == 'offered'),
                    ),
                ],
              );
            },
          ),
    );
  }
}

class _CopyLine extends StatelessWidget {
  const _CopyLine(this.label, this.value, {this.display});
  final String label, value;
  final String? display;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(display ?? value),
    trailing: IconButton(
      tooltip: 'Sao chép $label',
      icon: const Icon(Icons.copy_outlined),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(const SnackBar(content: Text('Đã sao chép')));
        }
      },
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.payload)
    : qr = QrImage(
        QrCode.fromData(
          data: payload,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        ),
      );
  final String payload;
  final QrImage qr;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final unit = (size.shortestSide / (qr.moduleCount + 8)).floorToDouble();
    final offset = (size.shortestSide - qr.moduleCount * unit) / 2;
    final black = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var y = 0; y < qr.moduleCount; y++) {
      for (var x = 0; x < qr.moduleCount; x++) {
        if (qr.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(offset + x * unit, offset + y * unit, unit, unit),
            black,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.payload != payload;
}
