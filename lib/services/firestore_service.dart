import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/week_plan.dart';
import '../services/firestore_service.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new week plan
  Future<void> createWeekPlan(WeekPlan weekPlan) async {
    await _db.collection('weekPlans').add(weekPlan.toJson());
  }

  // Fetch all week plans for a user
  Stream<List<WeekPlan>> getWeekPlans(String userId) {
    return _db
        .collection('weekPlans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WeekPlan.fromJson(doc.data(), id: doc.id)).toList());
  }

  // Update a week plan
  Future<void> updateWeekPlan(String weekPlanId, WeekPlan weekPlan) async {
    await _db.collection('weekPlans').doc(weekPlanId).update(weekPlan.toJson());
  }

  // Get a single week plan by ID
  Future<WeekPlan?> getWeekPlanById(String weekPlanId) async {
    final doc = await _db.collection('weekPlans').doc(weekPlanId).get();
    if (doc.exists) {
      return WeekPlan.fromJson(doc.data()!, id: doc.id);
    }
    return null;
  }

  // Fetch the current week plan for a user (by week number and year)
  Future<WeekPlan?> fetchCurrentWeekPlan(String userId) async {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final year = now.year;
    final query = await _db
        .collection('weekPlans')
        .where('userId', isEqualTo: userId)
        .where('weekNumber', isEqualTo: weekNumber)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return WeekPlan.fromJson(doc.data(), id: doc.id);
    }
    return null;
  }

  // Fetch all recipes for a user
  Future<List<Map<String, dynamic>>> fetchRecipes(String userId) async {
    final query = await _db.collection('recipes').where('userId', isEqualTo: userId).get();
    return query.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  // Fetch a single recipe by its ID
  Future<Map<String, dynamic>?> fetchRecipeById(String recipeId) async {
    final doc = await _db.collection('recipes').doc(recipeId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  int _getWeekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final thursday = date.add(Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final daysDifference = thursday.difference(firstDayOfYear).inDays;
    return 1 + (daysDifference / 7).floor();
  }
}

// Provider for FirestoreService singleton
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService.instance);

// Provider for current Firebase user
final firebaseUserProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

// Provider for week plans for the current user
final weekPlansProvider = StreamProvider<List<WeekPlan>>((ref) {
  final user = ref.watch(firebaseUserProvider).asData?.value;
  if (user == null) return const Stream.empty();
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWeekPlans(user.uid);
});

// Provider for recipes for the current user (if needed)
final recipesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.fetchRecipes(userId);
});
