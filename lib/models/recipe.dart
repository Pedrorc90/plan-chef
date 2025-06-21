import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final List<String> ingredients;
  final String createdBy;
  final String householdId;
  final List<String> mealTypes;
  final DateTime createdAt;
  final List<String> comments;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.createdBy,
    required this.householdId,
    required this.mealTypes,
    required this.createdAt,
    required this.comments,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      createdBy: data['createdBy'] ?? '',
      householdId: data['householdId'] ?? '',
      mealTypes: List<String>.from(data['mealTypes'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      comments: List<String>.from(data['comments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ingredients': ingredients,
      'createdBy': createdBy,
      'householdId': householdId,
      'mealTypes': mealTypes,
      'createdAt': Timestamp.fromDate(createdAt),
      'comments': comments,
    };
  }
}
