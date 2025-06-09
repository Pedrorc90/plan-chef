import 'package:flutter/material.dart';

import 'menu_generator_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onGenerateMenu;
  const HomeScreen({super.key, this.onGenerateMenu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Menú Semanal Actual',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(
              7,
              (index) => Card(
                    child: ListTile(
                      title: Text('Día ${index + 1}'),
                      subtitle: const Text('Desayuno, Comida, Cena'),
                    ),
                  )),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: onGenerateMenu,
              child: const Text('Generar nuevo menú'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
