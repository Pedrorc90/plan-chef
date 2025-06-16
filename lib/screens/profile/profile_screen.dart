// Dart models for WeekPlan
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Link with another user by email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email para compartir hogar',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Vincular con usuario'),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Introduce un email válido.')),
                  );
                  return;
                }
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) throw Exception('Usuario no autenticado');
                  // Buscar usuario por email en Firestore users collection
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
                  if (userQuery.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario no encontrado.')),
                    );
                    return;
                  }
                  final otherUserId = userQuery.docs.first.id;
                  // Comprobar si ya existe un household con ambos usuarios
                  final existing = await FirebaseFirestore.instance
                      .collection('households')
                      .where('userIds', arrayContains: currentUser.uid)
                      .get();
                  bool alreadyLinked = false;
                  for (var doc in existing.docs) {
                    final userIds = List<String>.from(doc['userIds'] ?? []);
                    if (userIds.contains(otherUserId) && userIds.length == 2) {
                      alreadyLinked = true;
                      break;
                    }
                  }
                  if (alreadyLinked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ya tienes un hogar compartido con este usuario.')),
                    );
                    return;
                  }
                  // Crear colección household con ambos usuarios
                  await FirebaseFirestore.instance.collection('households').add({
                    'userIds': [currentUser.uid, otherUserId],
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hogar compartido creado con $email.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            // Logout button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
