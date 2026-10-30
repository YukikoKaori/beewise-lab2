import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tutor.dart';

abstract interface class TutorRepository {
  Future<List<Tutor>> activeTutors({int limit = 50});
  Future<Tutor> tutorById(String id);
}

class FirebaseTutorRepository implements TutorRepository {
  FirebaseTutorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('tutors')
        .where('active', isEqualTo: true)
        .limit(limit.clamp(1, 100))
        .get();
    return snapshot.docs
        .map((doc) => Tutor.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<Tutor> tutorById(String id) async {
    final doc = await _firestore.collection('tutors').doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null || data['active'] != true) {
      throw const TutorNotFoundException();
    }
    return Tutor.fromMap(doc.id, data);
  }
}

class TutorNotFoundException implements Exception {
  const TutorNotFoundException();
  @override
  String toString() =>
      'Không tìm thấy hồ sơ gia sư hoặc hồ sơ đã ngừng hoạt động.';
}

class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException();
  @override
  String toString() => 'Firebase chưa được cấu hình cho ứng dụng BeeWise.';
}

class TutorSearchCriteria {
  const TutorSearchCriteria({
    this.query = '',
    this.area,
    this.subject,
    this.maxHourlyFee,
    this.teachingMode,
    this.sortByPrice = false,
  });

  final String query;
  final String? area;
  final String? subject;
  final int? maxHourlyFee;
  final String? teachingMode;
  final bool sortByPrice;

  @override
  bool operator ==(Object other) =>
      other is TutorSearchCriteria &&
      other.query == query &&
      other.area == area &&
      other.subject == subject &&
      other.maxHourlyFee == maxHourlyFee &&
      other.teachingMode == teachingMode &&
      other.sortByPrice == sortByPrice;

  @override
  int get hashCode => Object.hash(
    query,
    area,
    subject,
    maxHourlyFee,
    teachingMode,
    sortByPrice,
  );
}

List<Tutor> filterTutors(List<Tutor> tutors, TutorSearchCriteria criteria) {
  final query = criteria.query.trim().toLowerCase();
  final filtered = tutors.where((tutor) {
    final matchesQuery =
        query.isEmpty ||
        [
          tutor.name,
          tutor.credential,
          tutor.introduction,
          ...tutor.subjects,
          ...tutor.grades,
          ...tutor.areas,
        ].any((value) => value.toLowerCase().contains(query));
    return matchesQuery &&
        (criteria.area == null || tutor.areas.contains(criteria.area)) &&
        (criteria.subject == null ||
            tutor.subjects.contains(criteria.subject)) &&
        (criteria.maxHourlyFee == null ||
            tutor.hourlyFee <= criteria.maxHourlyFee!) &&
        (criteria.teachingMode == null ||
            tutor.teachingModes.contains(criteria.teachingMode));
  }).toList();
  if (criteria.sortByPrice) {
    filtered.sort((a, b) => a.hourlyFee.compareTo(b.hourlyFee));
  }
  return filtered;
}
