// Dart model for Household
import 'package:cloud_firestore/cloud_firestore.dart';

class Household {
  final String id;
  final List<String> userIds; // List of user UIDs

  Household({required this.id, required this.userIds});

  factory Household.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Household(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userIds': userIds,
    };
  }
}
