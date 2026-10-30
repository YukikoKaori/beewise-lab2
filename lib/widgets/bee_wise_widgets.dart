import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/tutor.dart';
import '../theme/bee_wise_theme.dart';

class BeeWiseScaffold extends StatelessWidget {
  const BeeWiseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.bottomNavigationIndex,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final bool showBack;
  final int? bottomNavigationIndex;
  final List<Widget> actions;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            )
          : null,
      title: Text(title),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(top: false, child: body),
    bottomNavigationBar: bottomNavigationIndex == null
        ? bottom
        : BeeWiseBottomNavigation(selectedIndex: bottomNavigationIndex!),
    floatingActionButton: floatingActionButton,
  );
}

class BeeWiseBottomNavigation extends StatelessWidget {
  const BeeWiseBottomNavigation({super.key, required this.selectedIndex});
  final int selectedIndex;

  static const _routes = [
    '/home',
    '/search',
    '/matching',
    '/messages',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) => context.go(_routes[index]),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Trang chủ',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_rounded),
        label: 'Tìm gia sư',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome_rounded),
        label: 'Ghép AI',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Tin nhắn',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Tài khoản',
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withGaps(children),
    ),
  );

  List<Widget> _withGaps(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(const SizedBox(height: BeeWiseSpace.x4));
      result.add(items[i]);
    }
    return result;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      ?trailing,
    ],
  );
}

class BeeWiseButton extends StatelessWidget {
  const BeeWiseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool secondary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final button = secondary
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : FilledButton(onPressed: loading ? null : onPressed, child: child);
    return Semantics(
      container: true,
      button: true,
      onTap: onPressed,
      enabled: !loading && onPressed != null,
      label: label,
      excludeSemantics: true,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
    this.action,
  });
  final String message;
  final NoticeKind kind;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (kind) {
      NoticeKind.success => (
        BeeWiseColors.success,
        BeeWiseColors.successSoft,
        Icons.check_circle_outline,
      ),
      NoticeKind.warning => (
        BeeWiseColors.warning,
        BeeWiseColors.accentSoft,
        Icons.warning_amber_rounded,
      ),
      NoticeKind.error => (
        BeeWiseColors.error,
        BeeWiseColors.errorSoft,
        Icons.error_outline,
      ),
      NoticeKind.info => (
        BeeWiseColors.primary,
        const Color(0xFFEEF2FF),
        Icons.info_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BeeWiseRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: BeeWiseColors.ink),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NoticeKind { info, success, warning, error }

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.label = 'Đang tải thông tin…'});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: BeeWiseColors.surface,
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      border: Border.all(color: BeeWiseColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: BeeWiseColors.muted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => StatusBanner(
    message: message,
    kind: NoticeKind.error,
    action: onRetry == null
        ? null
        : TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
  );
}

class FirebaseSetupNotice extends StatelessWidget {
  const FirebaseSetupNotice({super.key});
  @override
  Widget build(BuildContext context) => const StatusBanner(
    kind: NoticeKind.warning,
    message: 'Ứng dụng chưa kết nối Firebase. Hãy tạo Firebase project, chạy flutterfire configure và bật các dịch vụ trong README để tải dữ liệu thật.',
  );
}

class TutorAvatar extends StatelessWidget {
  const TutorAvatar({super.key, required this.tutor, this.radius = 28});
  final Tutor tutor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = tutor.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: BeeWiseColors.highlight,
      foregroundImage: image == null || image.isEmpty
          ? null
          : NetworkImage(image),
      onForegroundImageError: image == null ? null : (_, _) {},
      child: image == null || image.isEmpty
          ? Text(
              _initials(tutor.name),
              style: Theme.of(context).textTheme.titleLarge,
            )
          : null,
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'G';
    return parts.length == 1
        ? parts.first.characters.first.toUpperCase()
        : '${parts.first.characters.first}${parts.last.characters.first}'
              .toUpperCase();
  }
}

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    required this.onOpen,
    this.actionLabel = 'Xem hồ sơ',
    this.subtitle,
  });
  final Tutor tutor;
  final VoidCallback onOpen;
  final String actionLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fee = NumberFormat.decimalPattern('vi_VN').format(tutor.hourlyFee);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TutorAvatar(tutor: tutor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tutor.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (tutor.verified)
                            const Icon(
                              Icons.verified,
                              color: BeeWiseColors.success,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ?? tutor.credential,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: BeeWiseColors.muted),
                      ),
                      if (tutor.rating != null) ...[
                        const SizedBox(height: 6),
                        _RatingChip(
                          rating: tutor.rating!,
                          count: tutor.reviewCount,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tutor.subjects.isNotEmpty)
                  _MetaChip(
                    icon: Icons.school_outlined,
                    label: tutor.subjects.take(2).join(' · '),
                  ),
                if (tutor.areas.isNotEmpty)
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: tutor.areas.take(2).join(' · '),
                  ),
                if (tutor.teachingModes.isNotEmpty)
                  _MetaChip(
                    icon: Icons.cast_for_education_outlined,
                    label: tutor.teachingModes.take(1).join(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học phí',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$feeđ/giờ',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: BeeWiseColors.primary),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: '$actionLabel: ${tutor.name}',
                  child: FilledButton(
                    onPressed: onOpen,
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});
  final double rating;
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: BeeWiseColors.accentSoft,
      borderRadius: BorderRadius.circular(BeeWiseRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: BeeWiseColors.warning, size: 17),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          ' ($count)',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: BeeWiseColors.muted),
        ),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, color: BeeWiseColors.primary, size: 18),
    label: Text(label),
    backgroundColor: const Color(0xFFEEF2FF),
    side: BorderSide.none,
    visualDensity: VisualDensity.compact,
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, color: BeeWiseColors.primary, size: 22),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: BeeWiseColors.muted),
            ),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    ],
  );
}

class LoadingTutorList extends StatelessWidget {
  const LoadingTutorList({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 178,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(BeeWiseRadius.card),
            ),
            child: const Center(child: LinearProgressIndicator()),
          ),
        ),
    ],
  );
}
