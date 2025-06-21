// Dart model for DayPlan
class DayPlan {
  final String id;
  final Map<String, String> meals; // mealType -> recipeId

  DayPlan({required this.id, required this.meals});

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        id: json['id'] as String,
        meals: Map<String, String>.from(json['meals'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meals': meals,
      };

  DayPlan copyWith({String? id, Map<String, String>? meals}) {
    return DayPlan(
      id: id ?? this.id,
      meals: meals ?? this.meals,
    );
  }
}
