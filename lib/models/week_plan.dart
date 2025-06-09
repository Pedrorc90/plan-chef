// Dart models for WeekPlan and DayPlan
import 'package:cloud_firestore/cloud_firestore.dart';

class DayPlan {
  final String id;
  final Map<String, String> meals; // mealType -> recipeId

  DayPlan({required this.id, required this.meals});

  factory DayPlan.fromMap(String id, Map<String, dynamic> data) {
    return DayPlan(
      id: id,
      meals: Map<String, String>.from(data['meals'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meals': meals,
    };
  }
}

class WeekPlan {
  final String id;
  final String userId;
  final int weekNumber;
  final int year;
  final List<DayPlan> days;
  final DateTime createdAt;

  WeekPlan({
    required this.id,
    required this.userId,
    required this.weekNumber,
    required this.year,
    required this.days,
    required this.createdAt,
  });

  factory WeekPlan.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeekPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      weekNumber: data['weekNumber'] ?? 0,
      year: data['year'] ?? 0,
      days: (data['days'] as List<dynamic>? ?? [])
          .asMap()
          .entries
          .map(
              (entry) => DayPlan.fromMap(entry.key.toString(), entry.value as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weekNumber': weekNumber,
      'year': year,
      'days': days.map((d) => d.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
