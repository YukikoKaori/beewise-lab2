import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../services/tutor_application_service.dart';
import 'chat_message.dart';
import 'tutor.dart';

/// Explicit state classification for every tutor workspace data source.
enum TutorDataSourceState {
  loading,
  emptyVerified,
  populated,
  rulesBlocked,
  unauthorized,
  notFound,
  networkError,
  unknownError,
}

/// Canonical authority classification for routing and repository access.
enum AccountRoleKind {
  guest,
  parent,
  pendingApplicant,
  needsInfoApplicant,
  rejectedApplicant,
  approvedPendingVerification,
  authorizedTutor,
  unresolved,
}

class AccountRoleResolution {
  const AccountRoleResolution({
    required this.kind,
    this.uid,
    this.application,
    this.error,
  });

  final AccountRoleKind kind;
  final String? uid;
  final TutorApplicationData? application;
  final Object? error;

  bool get isAuthorizedTutor => kind == AccountRoleKind.authorizedTutor;
  bool get isApplicantOrTutor =>
      kind == AccountRoleKind.pendingApplicant ||
      kind == AccountRoleKind.needsInfoApplicant ||
      kind == AccountRoleKind.rejectedApplicant ||
      kind == AccountRoleKind.approvedPendingVerification ||
      kind == AccountRoleKind.authorizedTutor;
}

class TutorUnauthorizedException implements Exception {
  const TutorUnauthorizedException([
    this.message = 'Bạn không có quyền truy cập dữ liệu gia sư này.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class TutorResourceNotFoundException implements Exception {
  const TutorResourceNotFoundException([
    this.message = 'Không tìm thấy dữ liệu được yêu cầu.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class TutorBackendRulesDependencyException implements Exception {
  const TutorBackendRulesDependencyException([
    this.message = 'Chức năng này chưa được cấp quyền đồng bộ cho tài khoản gia sư. Vui lòng liên hệ BeeWise.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class TutorNetworkException implements Exception {
  const TutorNetworkException([
    this.message = 'Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.',
  ]);

  final String message;

  @override
  String toString() => message;
}

TutorDataSourceState classifyTutorDataError(Object error) {
  if (error is TutorBackendRulesDependencyException) {
    return TutorDataSourceState.rulesBlocked;
  }
  if (error is TutorUnauthorizedException) {
    return TutorDataSourceState.unauthorized;
  }
  if (error is TutorResourceNotFoundException) {
    return TutorDataSourceState.notFound;
  }
  if (error is TutorNetworkException || error is TimeoutException) {
    return TutorDataSourceState.networkError;
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => TutorDataSourceState.rulesBlocked,
      'unauthenticated' => TutorDataSourceState.unauthorized,
      'not-found' => TutorDataSourceState.notFound,
      'unavailable' ||
      'network-request-failed' ||
      'deadline-exceeded' => TutorDataSourceState.networkError,
      _ => TutorDataSourceState.unknownError,
    };
  }
  return TutorDataSourceState.unknownError;
}

/// Summary of an authorized group chat where the tutor is a participant.
class TutorChatSummary {
  const TutorChatSummary({
    required this.id,
    required this.parentId,
    required this.tutorId,
    required this.parentName,
    required this.onboardingStatus,
    this.consultantName,
    this.subjectSummary = '',
    this.areaSummary = '',
    this.lastMessageText,
    this.classId,
    this.isNew = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String parentId;
  final String tutorId;
  final String parentName;
  final String onboardingStatus;
  final String? consultantName;
  final String subjectSummary;
  final String areaSummary;
  final String? lastMessageText;
  final String? classId;
  final bool isNew;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get parentInitials => _computeInitials(parentName, fallback: 'PH');
  String get consultantInitials =>
      _computeInitials(consultantName ?? 'Tư vấn viên', fallback: 'TV');

  String get onboardingStatusLabel => switch (onboardingStatus) {
    'connection_pending_consultant' => 'Đang chờ tư vấn viên tham gia',
    'consultant_assigned' => 'Tư vấn viên đã tham gia nhóm',
    'trial_proposed' => 'Chờ phụ huynh xác nhận học thử',
    'trial_accepted' => 'Đã xác nhận lịch học thử',
    'trial_reschedule_requested' => 'Phụ huynh đề xuất giờ học thử khác',
    'class_revision_pending' => 'Chờ phụ huynh xác nhận thông tin lớp',
    'class_adjustment_requested' => 'Phụ huynh yêu cầu điều chỉnh lớp',
    'invoice_issued' || 'payment_pending' => 'Chờ phụ huynh thanh toán',
    'schedule_confirmed' || 'verified' || 'active' => 'Lớp học đã xác nhận',
    _ => 'Đang trao đổi',
  };

  factory TutorChatSummary.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final status = map['onboardingStatus'] as String? ?? '';
    return TutorChatSummary(
      id: id,
      parentId: map['parentId'] as String? ?? '',
      tutorId: map['tutorId'] as String? ?? '',
      parentName: (map['parentName'] as String?)?.trim().isNotEmpty == true
          ? (map['parentName'] as String).trim()
          : 'Phụ huynh',
      onboardingStatus: status,
      consultantName:
          (map['consultantName'] as String?)?.trim().isNotEmpty == true
          ? (map['consultantName'] as String).trim()
          : null,
      subjectSummary: (map['subjectSummary'] as String?)?.trim() ?? '',
      areaSummary: (map['areaSummary'] as String?)?.trim() ?? '',
      lastMessageText: (map['lastMessageText'] as String?)?.trim(),
      classId: (map['classId'] as String?)?.trim(),
      isNew: map['isNew'] as bool? ?? status == 'connection_pending_consultant',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

/// Complete state of a single tutor group chat screen (T4).
class TutorChatSession {
  const TutorChatSession({
    required this.summary,
    required this.messages,
    required this.canSendMessages,
    this.sendDisabledReason,
  });

  final TutorChatSummary summary;
  final List<ChatMessage> messages;
  final bool canSendMessages;
  final String? sendDisabledReason;
}

/// A single scheduled lesson session for T3 and T6.
class TutorLessonSession {
  const TutorLessonSession({
    required this.id,
    required this.classId,
    required this.tutorId,
    required this.subjectTitle,
    required this.parentName,
    required this.locationSummary,
    required this.startTime,
    required this.endTime,
    this.studentName,
    this.sessionNumber,
    this.totalSessions,
    this.confirmed = false,
  });

  final String id;
  final String classId;
  final String tutorId;
  final String subjectTitle;
  final String parentName;
  final String? studentName;
  final String locationSummary;
  final DateTime startTime;
  final DateTime endTime;
  final int? sessionNumber;
  final int? totalSessions;
  final bool confirmed;

  String get weekdayTileLabel => switch (startTime.weekday) {
    DateTime.monday => 'T2',
    DateTime.tuesday => 'T3',
    DateTime.wednesday => 'T4',
    DateTime.thursday => 'T5',
    DateTime.friday => 'T6',
    DateTime.saturday => 'T7',
    DateTime.sunday => 'CN',
    _ => 'T2',
  };

  String get weekdayLongLabel => switch (startTime.weekday) {
    DateTime.monday => 'Thứ hai',
    DateTime.tuesday => 'Thứ ba',
    DateTime.wednesday => 'Thứ tư',
    DateTime.thursday => 'Thứ năm',
    DateTime.friday => 'Thứ sáu',
    DateTime.saturday => 'Thứ bảy',
    DateTime.sunday => 'Chủ nhật',
    _ => 'Thứ hai',
  };

  String get timeAndDateLabel {
    final startStr = DateFormat('HH:mm').format(startTime);
    final endStr = DateFormat('HH:mm').format(endTime);
    final dateStr = DateFormat('dd/MM').format(startTime);
    return '$startStr - $endStr · $weekdayLongLabel $dateStr';
  }

  String get subtitleLabel {
    final parts = <String>[
      if (parentName.trim().isNotEmpty) parentName.trim(),
      if (subjectTitle.trim().isNotEmpty) subjectTitle.trim(),
      if (locationSummary.trim().isNotEmpty) locationSummary.trim(),
    ];
    return parts.isEmpty ? 'Chưa cập nhật chi tiết' : parts.join(' · ');
  }

  String get sessionProgressLabel {
    if (sessionNumber != null && totalSessions != null && totalSessions! > 0) {
      return confirmed
          ? 'Buổi $sessionNumber/$totalSessions · Đã xác nhận'
          : 'Buổi $sessionNumber/$totalSessions';
    }
    return confirmed ? 'Đã xác nhận' : 'Lịch dự kiến';
  }

  factory TutorLessonSession.fromMap(
    String id,
    Map<String, dynamic> map, {
    String fallbackClassId = '',
    String fallbackTutorId = '',
    String fallbackSubject = '',
    String fallbackParent = '',
    String fallbackLocation = '',
  }) {
    DateTime parseDateTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final start = parseDateTime(map['startTime'], now);
    final end = parseDateTime(
      map['endTime'],
      start.add(const Duration(hours: 2)),
    );

    return TutorLessonSession(
      id: id,
      classId: map['classId'] as String? ?? fallbackClassId,
      tutorId: map['tutorId'] as String? ?? fallbackTutorId,
      subjectTitle: map['subjectTitle'] as String? ?? fallbackSubject,
      parentName: map['parentName'] as String? ?? fallbackParent,
      studentName: map['studentName'] as String?,
      locationSummary: map['locationSummary'] as String? ?? fallbackLocation,
      startTime: start,
      endTime: end,
      sessionNumber: (map['sessionNumber'] as num?)?.round(),
      totalSessions: (map['totalSessions'] as num?)?.round(),
      confirmed: map['confirmed'] as bool? ?? false,
    );
  }
}

/// Authorized class detail model for T3 and T5.
class TutorClassRecord {
  const TutorClassRecord({
    required this.id,
    required this.tutorId,
    required this.parentId,
    required this.title,
    required this.parentName,
    required this.scheduleSummary,
    required this.locationSummary,
    required this.paymentStatus,
    this.chatId,
    this.studentName,
    this.studentLevel,
    this.hourlyFee,
    this.hoursPerSession,
    this.totalSessions,
    this.totalAmount,
    this.consultantName,
    this.onboardingStage = 1,
    this.nextSessionSummary,
    this.sessions = const [],
  });

  final String id;
  final String tutorId;
  final String parentId;
  final String? chatId;
  final String title;
  final String parentName;
  final String? studentName;
  final String? studentLevel;
  final String scheduleSummary;
  final String locationSummary;
  final int? hourlyFee;
  final double? hoursPerSession;
  final int? totalSessions;
  final int? totalAmount;
  final String? consultantName;
  final String paymentStatus;
  final int onboardingStage;
  final String? nextSessionSummary;
  final List<TutorLessonSession> sessions;

  /// Only true when server-authoritative `paymentStatus == 'verified'`.
  bool get isPaymentVerified => paymentStatus == 'verified';

  String get parentInitials => _computeInitials(parentName, fallback: 'PH');

  String get studentSummaryText {
    final parts = <String>[
      if (studentName != null && studentName!.trim().isNotEmpty)
        'Học sinh: ${studentName!.trim()}',
      if (studentLevel != null && studentLevel!.trim().isNotEmpty)
        'Học lực: ${studentLevel!.trim()}',
    ];
    return parts.isEmpty
        ? 'Chưa cập nhật thông tin học sinh'
        : parts.join(' · ');
  }

  String get feeBreakdownText {
    final fmt = NumberFormat.decimalPattern('vi_VN');
    final parts = <String>[];
    if (hourlyFee != null && hourlyFee! > 0) {
      parts.add('${fmt.format(hourlyFee)}đ/giờ');
    }
    if (hoursPerSession != null && hoursPerSession! > 0) {
      final h = hoursPerSession! == hoursPerSession!.roundToDouble()
          ? '${hoursPerSession!.round()}'
          : '$hoursPerSession';
      parts.add('$h giờ');
    }
    if (totalSessions != null && totalSessions! > 0) {
      parts.add('$totalSessions buổi');
    }
    if (totalAmount != null && totalAmount! > 0) {
      parts.add('${fmt.format(totalAmount)}đ');
    }
    return parts.isEmpty ? 'Chưa cập nhật học phí' : parts.join(' · ');
  }

  factory TutorClassRecord.fromMap(String id, Map<String, dynamic> map) {
    final tutorId = map['tutorId'] as String? ?? '';
    final title = (map['title'] as String?)?.trim().isNotEmpty == true
        ? (map['title'] as String).trim()
        : ((map['subject'] as String?)?.trim().isNotEmpty == true
              ? (map['subject'] as String).trim()
              : 'Lớp học');
    final parentName = (map['parentName'] as String?)?.trim().isNotEmpty == true
        ? (map['parentName'] as String).trim()
        : 'Phụ huynh';
    String? firstText(List<String> keys) {
      for (final key in keys) {
        final value = (map[key] as String?)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final location =
        firstText(['locationSummary', 'location', 'area']) ??
        'Chưa cập nhật địa điểm';
    final paymentStatus = map['paymentStatus'] as String? ?? 'pending';
    final rawStage = (map['onboardingStage'] as num?)?.round();
    final stage = rawStage != null
        ? rawStage.clamp(1, 4)
        : (paymentStatus == 'verified' ? 4 : 2);

    final rawSessions = map['sessions'];
    final parsedSessions = <TutorLessonSession>[];
    if (rawSessions is Iterable) {
      var index = 0;
      for (final item in rawSessions) {
        if (item is Map) {
          parsedSessions.add(
            TutorLessonSession.fromMap(
              item['id']?.toString() ?? '${id}_s${++index}',
              Map<String, dynamic>.from(item),
              fallbackClassId: id,
              fallbackTutorId: tutorId,
              fallbackSubject: title,
              fallbackParent: parentName,
              fallbackLocation: location,
            ),
          );
        }
      }
    }

    return TutorClassRecord(
      id: id,
      tutorId: tutorId,
      parentId: map['parentId'] as String? ?? '',
      chatId: (map['chatId'] as String?)?.trim(),
      title: title,
      parentName: parentName,
      studentName: (map['studentName'] as String?)?.trim(),
      studentLevel: (map['studentLevel'] as String?)?.trim(),
      scheduleSummary:
          firstText(['scheduleSummary']) ??
          [
            firstText(['schedule']),
            firstText(['time']),
          ].whereType<String>().join(' · ').trim().nullIfEmpty ??
          'Chưa cập nhật lịch học',
      locationSummary: location,
      hourlyFee: ((map['hourlyFee'] ?? map['fee']) as num?)?.round(),
      hoursPerSession: (map['hoursPerSession'] as num?)?.toDouble(),
      totalSessions: ((map['totalSessions'] ?? map['sessionCount']) as num?)
          ?.round(),
      totalAmount: ((map['totalAmount'] ?? map['totalFee']) as num?)?.round(),
      consultantName: (map['consultantName'] as String?)?.trim(),
      paymentStatus: paymentStatus,
      onboardingStage: stage,
      nextSessionSummary: (map['nextSessionSummary'] as String?)?.trim(),
      sessions: List.unmodifiable(parsedSessions),
    );
  }
}

/// Aggregated dashboard data for T3 (`TutorHomeScreen`).
class TutorDashboardData {
  const TutorDashboardData({
    this.tutorUid,
    this.chats = const [],
    this.upcomingSessions = const [],
    this.activeClasses = const [],
    TutorDataSourceState? chatsState,
    TutorDataSourceState? classesState,
    this.chatsBlockMessage,
    this.classesBlockMessage,
    this.backendAccessLimitation,
    // ignore: prefer_initializing_formals
  }) : _chatsState = chatsState,
       // ignore: prefer_initializing_formals
       _classesState = classesState;

  final String? tutorUid;
  final List<TutorChatSummary> chats;
  final List<TutorLessonSession> upcomingSessions;
  final List<TutorClassRecord> activeClasses;
  final TutorDataSourceState? _chatsState;
  final TutorDataSourceState? _classesState;
  final String? chatsBlockMessage;
  final String? classesBlockMessage;
  final String? backendAccessLimitation;

  TutorDataSourceState get chatsState =>
      _chatsState ??
      (chats.isEmpty
          ? TutorDataSourceState.emptyVerified
          : TutorDataSourceState.populated);

  TutorDataSourceState get classesState =>
      _classesState ??
      (activeClasses.isEmpty && upcomingSessions.isEmpty
          ? TutorDataSourceState.emptyVerified
          : TutorDataSourceState.populated);

  bool get isChatsRulesBlocked =>
      chatsState == TutorDataSourceState.rulesBlocked;

  bool get isClassesRulesBlocked =>
      classesState == TutorDataSourceState.rulesBlocked;

  bool get hasRulesBlockedSource =>
      isChatsRulesBlocked ||
      isClassesRulesBlocked ||
      backendAccessLimitation != null;

  bool get isFullyRulesBlocked => isChatsRulesBlocked && isClassesRulesBlocked;

  /// True ONLY when both data sources succeeded with zero records and neither
  /// is blocked by Firestore security rules.
  bool get isVerifiedEmpty =>
      !hasRulesBlockedSource &&
      chatsState == TutorDataSourceState.emptyVerified &&
      classesState == TutorDataSourceState.emptyVerified &&
      chats.isEmpty &&
      upcomingSessions.isEmpty &&
      activeClasses.isEmpty;

  bool get isEmpty => isVerifiedEmpty;
}

/// Combined application and public catalog profile for T7 (`TutorSelfProfileScreen`).
class TutorProfileViewData {
  const TutorProfileViewData({
    required this.application,
    this.publicCatalogProfile,
    TutorDataSourceState? publicCatalogState,
  }) : publicCatalogState =
           publicCatalogState ??
           (publicCatalogProfile != null
               ? TutorDataSourceState.populated
               : TutorDataSourceState.emptyVerified);

  final TutorApplicationData application;
  final Tutor? publicCatalogProfile;
  final TutorDataSourceState publicCatalogState;

  bool get isPublishedInCatalog =>
      publicCatalogProfile != null && publicCatalogProfile!.active;

  bool get isVerified =>
      application.verified &&
      (publicCatalogProfile == null || publicCatalogProfile!.verified);

  String get displayName {
    final pubName = publicCatalogProfile?.name.trim() ?? '';
    if (pubName.isNotEmpty) return pubName;
    final appName = application.name.trim();
    if (appName.isNotEmpty) return appName;
    return 'Chưa cập nhật';
  }

  String get initials => _computeInitials(displayName, fallback: 'GS');

  String get qualificationText {
    final cred = publicCatalogProfile?.credential.trim() ?? '';
    if (cred.isNotEmpty) return cred;
    final qual = application.qualification.trim();
    if (qual.isNotEmpty) return qual;
    return 'Chưa cập nhật';
  }

  String? get ratingText {
    final profile = publicCatalogProfile;
    if (profile != null && profile.rating != null && profile.reviewCount > 0) {
      return '${profile.rating!.toStringAsFixed(1)} (${profile.reviewCount})';
    }
    return null;
  }

  String get subjectsAndGradesText {
    final subjects =
        (publicCatalogProfile?.subjects.isNotEmpty == true
                ? publicCatalogProfile!.subjects
                : application.subjects)
            .where((s) => s.trim().isNotEmpty)
            .toList(growable: false);
    final grades =
        (publicCatalogProfile?.grades.isNotEmpty == true
                ? publicCatalogProfile!.grades
                : application.grades)
            .where((g) => g.trim().isNotEmpty)
            .toList(growable: false);
    final parts = <String>[
      if (subjects.isNotEmpty) subjects.join(', '),
      if (grades.isNotEmpty) grades.join(', '),
    ];
    return parts.isEmpty ? 'Chưa cập nhật' : parts.join(' · ');
  }

  String get hourlyFeeText {
    final fee =
        (publicCatalogProfile != null && publicCatalogProfile!.hourlyFee > 0)
        ? publicCatalogProfile!.hourlyFee
        : application.hourlyFee;
    if (fee <= 0) return 'Chưa cập nhật';
    return '${NumberFormat.decimalPattern('vi_VN').format(fee)} đ/giờ';
  }

  String get areasAndModesText {
    final areas =
        (publicCatalogProfile?.areas.isNotEmpty == true
                ? publicCatalogProfile!.areas
                : application.areas)
            .where((a) => a.trim().isNotEmpty)
            .toList(growable: false);
    final rawModes =
        (publicCatalogProfile?.teachingModes.isNotEmpty == true
                ? publicCatalogProfile!.teachingModes
                : application.teachingModes)
            .where((m) => m.trim().isNotEmpty)
            .toList(growable: false);
    final modeLabels = rawModes
        .map(
          (m) => switch (m) {
            'online' => 'Trực tuyến',
            'in_person' => 'Trực tiếp',
            _ => m,
          },
        )
        .toList(growable: false);
    final parts = <String>[
      if (areas.isNotEmpty) areas.join(', '),
      if (modeLabels.isNotEmpty) modeLabels.join(', '),
    ];
    return parts.isEmpty ? 'Chưa cập nhật' : parts.join(' · ');
  }

  String get availabilityText {
    final pubAvail = publicCatalogProfile?.availability.trim() ?? '';
    if (pubAvail.isNotEmpty) return pubAvail;
    final appAvail = application.availability.trim();
    if (appAvail.isNotEmpty) return appAvail;
    return 'Chưa cập nhật';
  }

  String get introductionText {
    final pubIntro = publicCatalogProfile?.introduction.trim() ?? '';
    if (pubIntro.isNotEmpty) return pubIntro;
    final appIntro = application.introduction.trim();
    if (appIntro.isNotEmpty) return appIntro;
    return 'Chưa cập nhật';
  }
}

String _computeInitials(String raw, {required String fallback}) {
  final parts = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return fallback;
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  final first = parts[parts.length - 2].characters.first;
  final second = parts.last.characters.first;
  return '$first$second'.toUpperCase();
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
