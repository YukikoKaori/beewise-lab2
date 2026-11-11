enum BeeWiseRole {
  user,
  staff,
  admin;

  static BeeWiseRole fromValue(Object? value) => switch (value) {
    'staff' => staff,
    'admin' => admin,
    _ => user,
  };

  bool get canReview => this == staff || this == admin;
}

enum TutorReviewDecision {
  approved,
  rejected,
  needsInfo;

  String get wireValue => this == needsInfo ? 'needs_info' : name;
}

bool isAuthorizedTutor({
  required String status,
  required bool verified,
  required bool active,
}) => status == 'approved' && verified && active;
