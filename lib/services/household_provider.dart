import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/models/week_plan.dart';

import 'firestore_service.dart';
import 'household_provider.dart';

/// Provides the current user's householdId (first household found)
final householdIdProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(firebaseUserProvider.future);
  if (user == null) return null;
  final firestore = ref.read(firestoreServiceProvider);
  // Fetch all households for the user
  final query = await firestore.db
      .collection('households')
      .where('userIds', arrayContains: user.uid)
      .limit(1)
      .get();
  if (query.docs.isEmpty) return null;
  return query.docs.first.id;
});
