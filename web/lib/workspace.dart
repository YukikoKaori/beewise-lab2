import 'dart:async';

import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'main.dart' show AdminSession;
import 'payment_workspace.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.title, this.detail, this.action});

  final String title;
  final String? detail;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Card(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (detail != null) ...[const SizedBox(height: 8), Text(detail!)],
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: action, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    ),
  );
}

const _labels = ['Tổng quan', 'Gia sư', 'Duyệt hồ sơ', 'Thông báo', 'VietQR'];
const _icons = [
  Icons.dashboard_outlined,
  Icons.school_outlined,
  Icons.fact_check_outlined,
  Icons.campaign_outlined,
  Icons.qr_code_outlined,
];

class AdminWorkspace extends StatefulWidget {
  const AdminWorkspace({
    super.key,
    required this.session,
    required this.uid,
    required this.role,
  });
  final AdminSession session;
  final String uid;
  final BeeWiseRole role;

  @override
  State<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspace> {
  int _index = 0;

  void _open(int index) {
    setState(() => _index = index);
    unawaited(widget.session.event('admin_section_open', {'section': index}));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth >= 800;
      final session = widget.session;
      final pane = switch (_index) {
        0 => Dashboard(store: session.store),
        1 => TutorManagement(store: session.store, uid: widget.uid),
        2 => ReviewQueue(session: session, uid: widget.uid),
        3 => AnnouncementForm(session: session, uid: widget.uid),
        _ => PaymentWorkspace(
          store: ManualPayments(session.store.db),
          uid: widget.uid,
        ),
      };
      return Scaffold(
        appBar: AppBar(
          backgroundColor: BeeWiseColors.surface,
          title: const Text('BeeWise Admin'),
          leading: const Icon(Icons.hive_rounded, color: BeeWiseColors.primary),
          actions: [
            if (wide)
              Chip(
                label: Text(
                  widget.role == BeeWiseRole.admin
                      ? 'Quản trị viên'
                      : 'Nhân viên',
                ),
              ),
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: session.auth.signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _open,
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationDestination(
                      icon: Icon(_icons[i]),
                      label: _labels[i],
                    ),
                ],
              ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                extended: bounds.maxWidth >= 1060,
                labelType: bounds.maxWidth >= 1060
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                selectedIndex: _index,
                onDestinationSelected: _open,
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      label: Text(_labels[i]),
                    ),
                ],
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: ListView(
                    padding: EdgeInsets.all(
                      wide ? BeeWiseSpace.x8 : BeeWiseSpace.x4,
                    ),
                    children: [
                      Text(
                        _labels[_index],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      pane,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.store});
  final BeeWiseFirestore store;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late var _metrics = _load();

  Future<List<int>> _load() async {
    final store = widget.store;
    final results = await Future.wait([
      store.applications.count().get(),
      store.applications.where('status', isEqualTo: 'pending').count().get(),
      store.tutors
          .where('active', isEqualTo: true)
          .where('verified', isEqualTo: true)
          .count()
          .get(),
    ]);
    return [for (final result in results) result.count ?? 0];
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _metrics,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }
      final numbers = snapshot.data;
      if (numbers == null) {
        return StatusPanel(
          title: 'Không tải được số liệu',
          action: () => setState(() => _metrics = _load()),
        );
      }
      const labels = [
        'Tổng hồ sơ',
        'Chờ duyệt',
        'Gia sư đã xác minh đang hiển thị',
      ];
      final max = numbers.fold(1, (n, value) => value > n ? value : n);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _metrics = _load()),
              icon: const Icon(Icons.refresh),
              label: const Text('Cập nhật số liệu'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < labels.length; i++)
                SizedBox(
                  width: 245,
                  child: StatusPanel(title: '${numbers[i]}', detail: labels[i]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'So sánh số lượng',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (numbers.every((value) => value == 0))
                    const Text('Chưa có dữ liệu.'),
                  for (var i = 0; i < labels.length; i++) ...[
                    Text('${labels[i]}: ${numbers[i]}'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: numbers[i] / max,
                      minHeight: 10,
                      semanticsLabel: labels[i],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

typedef Record = QueryDocumentSnapshot<Map<String, dynamic>>;

class RecordList extends StatefulWidget {
  const RecordList({
    super.key,
    required this.query,
    required this.empty,
    required this.builder,
  });
  final Query<Map<String, dynamic>> query;
  final String empty;
  final Widget Function(List<Record>) builder;

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  late var _stream = widget.query.snapshots();

  @override
  void didUpdateWidget(RecordList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _stream = widget.query.snapshots();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) {
        return StatusPanel(
          title: 'Không tải được dữ liệu',
          detail: 'Kiểm tra kết nối và quyền của tài khoản.',
          action: () => setState(() => _stream = widget.query.snapshots()),
        );
      }
      final docs = snapshot.data?.docs ?? const <Record>[];
      if (docs.isEmpty) return StatusPanel(title: widget.empty);
      return widget.builder(docs);
    },
  );
}

class ReviewQueue extends StatelessWidget {
  const ReviewQueue({super.key, required this.session, required this.uid});
  final AdminSession session;
  final String uid;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Kiểm tra thông tin trước khi duyệt. Duyệt mở trang gia sư; đăng hồ sơ công khai là bước riêng.',
      ),
      const SizedBox(height: 12),
      RecordList(
        query: session.store.applications.where('status', isEqualTo: 'pending'),
        empty: 'Không có hồ sơ đang chờ duyệt.',
        builder: (records) => Card(
          child: Column(
            children: [
              for (final record in records)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_value(record.data()['name'])),
                  subtitle: const Text('Đang chờ duyệt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => ReviewDialog(
                      session: session,
                      uid: uid,
                      application: record,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('Hồ sơ đã xử lý', style: Theme.of(context).textTheme.titleMedium),
      RecordList(
        query: session.store.applications.where(
          'status',
          whereIn: ['approved', 'rejected', 'needs_info'],
        ),
        empty: 'Chưa có hồ sơ đã xử lý.',
        builder: (records) => Card(
          child: Column(
            children: [
              for (final record in records)
                ListTile(
                  title: Text(_value(record.data()['name'])),
                  subtitle: Text(_status(record.data()['status'])),
                  onTap: () => showDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => ReviewDialog(
                      session: session,
                      uid: uid,
                      application: record,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

String _value(Object? value) => switch (value) {
  null => '—',
  Iterable<Object?> entries => entries.join(', '),
  _ => value.toString(),
};

String _status(Object? value) => switch (value) {
  'approved' => 'Đã duyệt',
  'rejected' => 'Từ chối',
  'needs_info' => 'Cần bổ sung',
  _ => 'Đang chờ duyệt',
};

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({
    super.key,
    required this.session,
    required this.uid,
    required this.application,
  });
  final AdminSession session;
  final String uid;
  final Record application;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _reason = TextEditingController();
  bool _working = false;
  String? _error;

  Future<void> _review(TutorReviewDecision decision) async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Nhập lý do để ghi lại quyết định.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.session.store.review(
        applicantUid: widget.application.id,
        reviewerUid: widget.uid,
        decision: decision,
        reason: _reason.text,
      );
      unawaited(
        widget.session.event('admin_review_committed', {
          'decision': decision.wireValue,
        }),
      );
      if (mounted) Navigator.pop(context);
    } on StateError {
      if (mounted) {
        setState(
          () => _error = 'Hồ sơ đã được xử lý. Đóng và tải lại danh sách.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa lưu được quyết định. Kiểm tra quyền và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.application.data();
    final pending =
        data['status'] == 'pending' && widget.application.id != widget.uid;
    return AlertDialog(
      title: Text(_value(data['name'])),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in const {
                'email': 'Email',
                'phone': 'Điện thoại',
                'qualification': 'Chuyên môn',
                'introduction': 'Giới thiệu',
                'subjects': 'Môn',
                'grades': 'Khối',
                'areas': 'Khu vực',
                'availability': 'Lịch rảnh',
                'teachingModes': 'Hình thức',
                'hourlyFee': 'Phí dự kiến',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${entry.value}: ${_value(data[entry.key])}'),
                ),
              const Divider(),
              const Text('Lịch sử quyết định'),
              RecordList(
                query: widget.session.store
                    .reviews(widget.application.id)
                    .orderBy('createdAt', descending: true),
                empty: 'Chưa có quyết định trong Web Admin.',
                builder: (records) => Column(
                  children: [
                    for (final record in records)
                      ListTile(
                        title: Text(_status(record.data()['status'])),
                        subtitle: Text(_value(record.data()['reason'])),
                      ),
                  ],
                ),
              ),
              if (pending)
                TextField(
                  controller: _reason,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Lý do quyết định',
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: BeeWiseColors.error),
                ),
              if (_working) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (pending) ...[
          OutlinedButton(
            onPressed: _working
                ? null
                : () => _review(TutorReviewDecision.rejected),
            child: const Text('Từ chối'),
          ),
          OutlinedButton(
            onPressed: _working
                ? null
                : () => _review(TutorReviewDecision.needsInfo),
            child: const Text('Yêu cầu bổ sung'),
          ),
          FilledButton(
            onPressed: _working
                ? null
                : () => _review(TutorReviewDecision.approved),
            child: const Text('Duyệt hồ sơ'),
          ),
        ],
      ],
    );
  }
}

class TutorManagement extends StatefulWidget {
  const TutorManagement({super.key, required this.store, required this.uid});
  final BeeWiseFirestore store;
  final String uid;

  @override
  State<TutorManagement> createState() => _TutorManagementState();
}

class _TutorManagementState extends State<TutorManagement> {
  String _search = '';

  void _edit(Record record, {required bool creating}) => showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) =>
        CatalogDialog(store: widget.store, record: record, creating: creating),
  );

  void _chooseApplicant() => showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (dialog) => AlertDialog(
      title: const Text('Chọn hồ sơ đã được duyệt'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: RecordList(
            query: widget.store.applications.where(
              'status',
              isEqualTo: 'approved',
            ),
            empty: 'Chưa có hồ sơ được duyệt.',
            builder: (records) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final record in records.where(
                  (record) =>
                      record.id != widget.uid &&
                      record.data()['active'] == true &&
                      record.data()['verified'] == true,
                ))
                  ListTile(
                    title: Text(_value(record.data()['name'])),
                    subtitle: Text(_value(record.data()['qualification'])),
                    onTap: () {
                      Navigator.pop(dialog);
                      _edit(record, creating: true);
                    },
                  ),
                if (!records.any(
                  (record) =>
                      record.id != widget.uid &&
                      record.data()['active'] == true &&
                      record.data()['verified'] == true,
                ))
                  const Text('Chưa có hồ sơ đủ điều kiện công khai.'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Chỉ công khai hồ sơ đã xác minh. Hồ sơ Lab 3 cũ và hồ sơ demo chỉ đọc.',
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 330,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm theo tên hoặc môn',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
            ),
          ),
          FilledButton.icon(
            onPressed: _chooseApplicant,
            icon: const Icon(Icons.add),
            label: const Text('Đăng hồ sơ công khai'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      RecordList(
        query: widget.store.tutors,
        empty: 'Danh mục chưa có gia sư.',
        builder: (records) {
          final visible = records.where((record) {
            final data = record.data();
            return '${_value(data['name'])} ${_value(data['subjects'])}'
                .toLowerCase()
                .contains(_search);
          }).toList();
          if (visible.isEmpty) {
            return const StatusPanel(title: 'Không tìm thấy gia sư phù hợp.');
          }
          return Card(
            child: Column(
              children: [
                for (final record in visible)
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(_value(record.data()['name'])),
                    subtitle: Text(
                      record.data()['active'] == true
                          ? 'Đang hiển thị'
                          : 'Đã lưu trữ',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _edit(record, creating: false),
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

const _listingFields = {
  'name': ('Tên công khai', 2, 100),
  'credential': ('Chuyên môn', 2, 300),
  'introduction': ('Giới thiệu công khai', 20, 1000),
  'subjects': ('Môn (cách nhau bằng dấu phẩy)', 1, 300),
  'grades': ('Khối (cách nhau bằng dấu phẩy)', 1, 100),
  'areas': ('Khu vực (cách nhau bằng dấu phẩy)', 1, 500),
  'availability': ('Lịch rảnh', 2, 500),
  'hourlyFee': ('Phí mỗi giờ (VND)', 1, 9),
};

class CatalogDialog extends StatefulWidget {
  const CatalogDialog({
    super.key,
    required this.store,
    required this.record,
    required this.creating,
  });
  final BeeWiseFirestore store;
  final Record record;
  final bool creating;

  @override
  State<CatalogDialog> createState() => _CatalogDialogState();
}

class _CatalogDialogState extends State<CatalogDialog> {
  late final _data = widget.record.data();
  late final _editors = {
    for (final key in _listingFields.keys)
      key: TextEditingController(
        text: _value(
          _data[widget.creating && key == 'credential' ? 'qualification' : key],
        ),
      ),
  };
  late final _modes = {
    ...(_data['teachingModes'] as List? ?? []).whereType<String>(),
  };
  final _form = GlobalKey<FormState>();
  bool _working = false;
  String? _error;

  List<String> _values(String field) => _editors[field]!.text
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _save({bool archive = false}) async {
    if (!_form.currentState!.validate()) return;
    if (_modes.isEmpty ||
        ['subjects', 'grades', 'areas'].any(
          (key) =>
              _values(key).isEmpty ||
              _values(key).length > (key == 'grades' ? 12 : 10),
        )) {
      setState(
        () => _error = 'Kiểm tra môn, khối, khu vực và chọn hình thức dạy.',
      );
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    final ref = widget.store.tutors.doc(widget.record.id);
    try {
      final patch = <String, Object>{
        for (final key in [
          'name',
          'credential',
          'introduction',
          'availability',
        ])
          key: _editors[key]!.text.trim(),
        for (final key in ['subjects', 'grades', 'areas']) key: _values(key),
        'hourlyFee': int.parse(_editors['hourlyFee']!.text.trim()),
        'teachingModes': _modes.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await widget.store.db.runTransaction((tx) async {
        final current = await tx.get(ref);
        if (widget.creating) {
          if (current.exists) throw StateError('Catalog record already exists');
          tx.set(ref, {
            ...patch,
            'active': true,
            'verified': true,
            'applicationUid': ref.id,
            'managedByFinal': true,
            'publishedAt': FieldValue.serverTimestamp(),
          });
        } else {
          if (!current.exists) throw StateError('Catalog record is missing');
          tx.update(ref, {...patch, if (archive) 'active': false});
        }
      });
      if (mounted) Navigator.pop(context);
    } on StateError {
      if (mounted) {
        setState(() => _error = 'Hồ sơ công khai đã thay đổi. Đóng và mở lại.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Chưa lưu được. Kiểm tra quyền và trạng thái xét duyệt.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    for (final editor in _editors.values) {
      editor.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.creating || _data['managedByFinal'] == true;
    return AlertDialog(
      title: Text(widget.creating ? 'Đăng hồ sơ công khai' : 'Chi tiết gia sư'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nội dung này có thể xuất hiện công khai. Không nhập email, số điện thoại hay thông tin riêng tư.',
                ),
                const SizedBox(height: 12),
                for (final entry in _listingFields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _editors[entry.key],
                      readOnly: !editable || _working,
                      maxLines: entry.key == 'introduction' ? 3 : 1,
                      decoration: InputDecoration(labelText: entry.value.$1),
                      validator: (value) {
                        final clean = value?.trim() ?? '';
                        if (clean.length < entry.value.$2 ||
                            clean.length > entry.value.$3) {
                          return 'Kiểm tra độ dài nội dung.';
                        }
                        if (entry.key == 'hourlyFee') {
                          final amount = int.tryParse(clean);
                          if (amount == null ||
                              amount <= 0 ||
                              amount > 100000000) {
                            return 'Nhập mức phí hợp lệ.';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final mode in {
                      'online': 'Trực tuyến',
                      'in_person': 'Trực tiếp',
                    }.entries)
                      FilterChip(
                        label: Text(mode.value),
                        selected: _modes.contains(mode.key),
                        onSelected: !editable || _working
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _modes.add(mode.key);
                                } else {
                                  _modes.remove(mode.key);
                                }
                              }),
                      ),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: BeeWiseColors.error),
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
        if (editable && !widget.creating && _data['active'] == true)
          OutlinedButton(
            onPressed: _working ? null : () => _save(archive: true),
            child: const Text('Lưu trữ'),
          ),
        if (editable)
          FilledButton(
            onPressed: _working ? null : () => _save(),
            child: Text(widget.creating ? 'Công khai' : 'Lưu thay đổi'),
          ),
      ],
    );
  }
}

class AnnouncementForm extends StatefulWidget {
  const AnnouncementForm({super.key, required this.session, required this.uid});
  final AdminSession session;
  final String uid;

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _working = false;
  String? _result;
  bool _failed = false;

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _working = true;
      _result = null;
    });
    try {
      await widget.session.store.publishAnnouncement(
        uid: widget.uid,
        title: _title.text,
        body: _body.text,
      );
      unawaited(widget.session.event('admin_announcement_published'));
      if (!mounted) return;
      _title.clear();
      _body.clear();
      setState(() {
        _failed = false;
        _result = 'Đã đăng thông báo chung.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _result = 'Chưa đăng được. Kiểm tra quyền và kết nối rồi thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.config?.getBool('admin_announcements_enabled') ==
        false) {
      return const StatusPanel(title: 'Tạm dừng đăng thông báo');
    }
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Phụ huynh và gia sư đã đăng nhập sẽ thấy thông báo này. Không đưa thông tin riêng tư vào nội dung.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    maxLength: 120,
                    readOnly: _working,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Nhập tiêu đề.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _body,
                    maxLength: 2000,
                    minLines: 4,
                    maxLines: 7,
                    readOnly: _working,
                    decoration: const InputDecoration(labelText: 'Nội dung'),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Nhập nội dung.' : null,
                  ),
                  if (_working) const LinearProgressIndicator(),
                  if (_result != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _result!,
                        style: TextStyle(
                          color: _failed
                              ? BeeWiseColors.error
                              : BeeWiseColors.success,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _working ? null : _publish,
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Đăng thông báo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
