// Dart models for WeekPlan
import 'package:cloud_firestore/cloud_firestore.dart';
import 'day_plan.dart';

class WeekPlan {
  final String? id;
  final String householdId;
  final String createdBy;
  final int weekNumber;
  final int year;
  final List<DayPlan> days;
  final DateTime createdAt;

  WeekPlan({
    this.id,
    required this.householdId,
    required this.createdBy,
    required this.weekNumber,
    required this.year,
    required this.days,
    required this.createdAt,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> json, {String? id}) => WeekPlan(
        id: id,
        householdId: json['householdId'] ?? '',
        createdBy: json['createdBy'] ?? '',
        weekNumber: json['weekNumber'] ?? 0,
        year: json['year'] ?? 0,
        days: (json['days'] as List<dynamic>? ?? [])
            .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
            .toList(),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'householdId': householdId,
        'createdBy': createdBy,
        'weekNumber': weekNumber,
        'year': year,
        'days': days.map((d) => d.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
