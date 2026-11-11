import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'workspace.dart' show StatusPanel;

class PaymentWorkspace extends StatefulWidget {
  const PaymentWorkspace({super.key, required this.store, required this.uid});
  final ManualPayments store;
  final String uid;
  @override
  State<PaymentWorkspace> createState() => _PaymentWorkspaceState();
}

class _PaymentWorkspaceState extends State<PaymentWorkspace> {
  String _status = 'awaiting_verification';
  String _search = '';
  late Stream<QuerySnapshot<Map<String, dynamic>>> _rows = _query();

  Stream<QuerySnapshot<Map<String, dynamic>>> _query() {
    final source = widget.store.records;
    if (ManualPayments.validId.hasMatch(_search)) {
      return source.where('invoiceId', isEqualTo: _search).limit(1).snapshots();
    }
    final reference = _search.toUpperCase();
    if (RegExp(r'^BW[A-Z0-9]{16}$').hasMatch(reference)) {
      return source
          .where('transferReference', isEqualTo: reference)
          .limit(1)
          .snapshots();
    }
    return (_status.isEmpty
            ? source
            : source.where('status', isEqualTo: _status))
        .orderBy('createdAt', descending: true)
        .limit(75)
        .snapshots();
  }

  void _refresh() => setState(() => _rows = _query());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Đối chiếu số tiền và nội dung trên sao kê thật của tài khoản nhận. BeeWise không truy vấn ngân hàng; ảnh chụp hoặc lời khai không đủ để xác minh.',
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Phát hành đề xuất lớp'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _IssueDialog(widget.store, widget.uid),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Tìm mã hóa đơn hoặc nội dung chuyển khoản',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() {
          _search = value.trim();
          _rows = _query();
        }),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _status,
        decoration: const InputDecoration(labelText: 'Trạng thái'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tất cả')),
          for (final status in [
            'offered',
            'awaiting_transfer',
            'awaiting_verification',
            'verified',
            'rejected',
            'cancelled',
          ])
            DropdownMenuItem(
              value: status,
              child: Text(ManualPayments.statusLabel(status)),
            ),
        ],
        onChanged: (status) => setState(() {
          _status = status ?? '';
          _rows = _query();
        }),
      ),
      const SizedBox(height: 16),
      StreamBuilder(
        stream: _rows,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StatusPanel(
              title: 'Chưa tải được thanh toán',
              action: _refresh,
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final rows = snapshot.data!.docs.where((item) {
            final d = item.data();
            return (_status.isEmpty || d['status'] == _status) &&
                (_search.isEmpty ||
                    item.id.toLowerCase().contains(_search.toLowerCase()) ||
                    '${d['transferReference']}'.toLowerCase().contains(
                      _search.toLowerCase(),
                    ));
          }).toList();
          if (rows.isEmpty) {
            return const StatusPanel(title: 'Không có hóa đơn phù hợp');
          }
          return Column(
            children: [
              for (final item in rows)
                Card(
                  child: ListTile(
                    title: Text(
                      '${item.data()['transferReference']} · ${item.data()['amount']} VND',
                    ),
                    subtitle: Text(
                      '${item.id} · ${ManualPayments.statusLabel(item.data()['status'] as String? ?? '')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _ReviewDialog(widget.store, widget.uid, item),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _IssueDialog extends StatefulWidget {
  const _IssueDialog(this.store, this.uid);
  final ManualPayments store;
  final String uid;
  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  final _fields = [for (var i = 0; i < 6; i++) TextEditingController()];
  final _form = GlobalKey<FormState>();
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final v = _fields.map((f) => f.text.trim()).toList();
      final amount = int.tryParse(v[5]);
      if (amount == null ||
          amount <= 0 ||
          amount > 100000000 ||
          !RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v[3])) {
        throw const FormatException(
          'Kiểm tra giờ HH:mm và số tiền VND nguyên dương.',
        );
      }
      await widget.store.issue(
        id: v[0],
        uid: widget.uid,
        subject: v[1],
        date: v[2],
        time: v[3],
        location: v[4],
        amount: amount,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException ? error.message : 'Không phát hành được. Kiểm tra quyền, kết nối và mã cuộc trò chuyện.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Mã cuộc trò chuyện',
      'Môn hoặc tên lớp',
      'Ngày học (YYYY-MM-DD)',
      'Giờ (HH:mm)',
      'Địa điểm / hình thức',
      'Tổng phí VND',
    ];
    return AlertDialog(
      title: const Text('Phát hành đề xuất lớp'),
      content: SizedBox(
        width: 510,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dùng mã từ cuộc trò chuyện Final. Firestore lấy đúng phụ huynh, gia sư và tài khoản nhận đã cấu hình. Phụ huynh phải xác nhận trước khi hiện QR.',
                ),
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      controller: _fields[i],
                      enabled: !_working,
                      maxLength: i == 4 ? 200 : 120,
                      decoration: InputDecoration(
                        labelText: labels[i],
                        counterText: '',
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Không được để trống.'
                          : null,
                    ),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_working) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _working ? null : _save,
          child: const Text('Phát hành'),
        ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog(this.store, this.uid, this.record);
  final ManualPayments store;
  final String uid;
  final PaymentRecord record;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _reason = TextEditingController();
  final _receipt = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  bool _checked = false, _working = false;
  String? _error;
  late final _history = widget.record.reference
      .collection('reviews')
      .orderBy('reviewedAt', descending: true)
      .limit(20)
      .snapshots();

  @override
  void dispose() {
    for (final field in [_reason, _receipt, _amount, _reference]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _decide(String action) async {
    final reason = _reason.text.trim();
    if (action != 'verified' && (reason.isEmpty || reason.length > 500)) {
      setState(() => _error = 'Cần ghi lý do từ 1 đến 500 ký tự.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final id = widget.record.id;
      if (action == 'cancelled') {
        await widget.store.cancel(id, widget.uid, reason);
      } else {
        final claim = widget.record.data()?['claimId'];
        if (claim is! String || (action == 'verified' && !_checked)) {
          throw const FormatException(
            'Kiểm tra lại yêu cầu và xác nhận đã đọc sao kê.',
          );
        }
        await widget.store.decide(
          id: id,
          uid: widget.uid,
          expectedClaim: claim,
          verify: action == 'verified',
          reason: reason,
          bankTransaction: _receipt.text,
          matchedAmount: int.tryParse(_amount.text.trim()),
          matchedReference: _reference.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException ? error.message : 'Không lưu được quyết định. Quyền có thể đã đổi, yêu cầu đã xử lý hoặc giao dịch đã được dùng.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.record.data()!;
    final status = d['status'];
    final canDecide = status == 'awaiting_verification';
    final canCancel = [
      'offered',
      'awaiting_transfer',
      'rejected',
    ].contains(status);
    final recipient = BankRecipient.parse(d['recipient']);
    return AlertDialog(
      title: Text('Hóa đơn ${widget.record.id}'),
      content: SizedBox(
        width: 590,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ManualPayments.statusLabel('$status')),
              SelectableText(
                'Phụ huynh: ${d['parentId']} · Cuộc trò chuyện: ${d['chatId']}',
              ),
              Text(
                '${d['subject']} · ${d['tutorName']} · ${d['date']} ${d['time']} · ${d['location']}',
              ),
              Text(
                'Cần nhận: ${d['amount']} VND · Nội dung: ${d['transferReference']}',
              ),
              if (recipient != null)
                Text(
                  'Người nhận: ${recipient.accountHolder} · BIN ${recipient.bankBin} · ${recipient.accountNumber}',
                ),
              if (d['claimedAt'] is Timestamp)
                Text(
                  'Đã báo chuyển: ${(d['claimedAt'] as Timestamp).toDate().toLocal()}',
                ),
              if (status == 'cancelled')
                Text('Hủy bởi ${d['cancelledBy']}: ${d['cancelReason']}'),
              if (canDecide) ...[
                const Divider(),
                const Text(
                  'Mở sao kê của chính tài khoản nhận và kiểm tra số tiền thực nhận cùng nội dung. Không xác nhận dựa vào ảnh hoặc lời khai.',
                ),
                _entry(_amount, 'Số tiền thực nhận (VND)', 9),
                _entry(_reference, 'Nội dung trên sao kê', 25),
                _entry(_receipt, 'Mã giao dịch ngân hàng (chữ và số)', 40),
                CheckboxListTile(
                  value: _checked,
                  onChanged: _working
                      ? null
                      : (value) => setState(() => _checked = value == true),
                  title: const Text(
                    'Tôi đã đối chiếu trực tiếp trên sao kê và các thông tin khớp.',
                  ),
                ),
              ],
              if (canDecide || canCancel)
                _entry(_reason, 'Lý do từ chối / hủy', 500),
              if (_working) const LinearProgressIndicator(),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const Divider(),
              Text(
                'Lịch sử đối soát',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              StreamBuilder(
                stream: _history,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Không tải được lịch sử.');
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.docs.isEmpty) {
                    return const Text('Chưa có quyết định.');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final review in snapshot.data!.docs)
                        Text(
                          '${ManualPayments.statusLabel('${review.data()['status']}')} · ${review.data()['reviewedBy']} · ${(review.data()['reviewedAt'] as Timestamp?)?.toDate().toLocal() ?? ''}${review.data()['reason'] == null ? '' : ' · ${review.data()['reason']}'}',
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (canCancel)
          OutlinedButton(
            onPressed: _working ? null : () => _decide('cancelled'),
            child: const Text('Hủy hóa đơn'),
          ),
        if (canDecide)
          OutlinedButton(
            onPressed: _working ? null : () => _decide('rejected'),
            child: const Text('Từ chối'),
          ),
        if (canDecide)
          FilledButton(
            onPressed: _working || !_checked ? null : () => _decide('verified'),
            child: const Text('Xác minh chuyển khoản'),
          ),
      ],
    );
  }

  Widget _entry(TextEditingController controller, String label, int max) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: controller,
          enabled: !_working,
          maxLength: max,
          decoration: InputDecoration(labelText: label, counterText: ''),
        ),
      );
}
