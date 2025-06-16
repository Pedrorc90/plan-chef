// Dart models for WeekPlan
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:plan_chef/firebase_options.dart';
import 'package:plan_chef/screens/auth/auth_screen.dart';
import 'package:plan_chef/screens/main_scaffold.dart';

import '../services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firebaseUserProvider);
    userAsync.whenData((user) async {
      if (user != null) {
        // Sync user to Firestore users collection
        final usersRef = FirebaseFirestore.instance.collection('users');
        await usersRef.doc(user.uid).set({
          'email': user.email,
          'uid': user.uid,
        }, SetOptions(merge: true));
      }
    });
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recetario Inteligente',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: userAsync.when(
        data: (user) {
          if (user != null) {
            return const MainScaffold();
          } else {
            return const AuthScreen();
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
