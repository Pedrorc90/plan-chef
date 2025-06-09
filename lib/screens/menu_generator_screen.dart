import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuGeneratorScreen extends ConsumerWidget {
  const MenuGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferencias para el menú',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const TextField(
              decoration: InputDecoration(labelText: 'Tipo de dieta (ej. vegetariana)')),
          const TextField(decoration: InputDecoration(labelText: 'Ingredientes a evitar')),
          const TextField(decoration: InputDecoration(labelText: 'Número de comidas por día')),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Generar menú semanal'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
