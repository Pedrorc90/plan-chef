import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'menu_generator_screen.dart';
import 'recipes_screen.dart';
import 'shopping_list_screen.dart';
import 'package:plan_chef/screens/week_plan_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetario Inteligente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: [
        HomeScreen(onGenerateMenu: () => _onItemTapped(2)),
        const RecipesScreen(),
        const MenuGeneratorScreen(),
        const ShoppingListScreen(),
        const WeekPlanScreen(),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recetas'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Generar Menú'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Semana'),
        ],
      ),
    );
  }
}
