import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/models/day_plan.dart';
import 'package:plan_chef/models/week_plan.dart';
import 'package:plan_chef/screens/home_screen.dart';
import 'package:plan_chef/screens/menu_generator_screen.dart';
import 'package:plan_chef/screens/recipes_screen.dart';
import 'package:plan_chef/screens/shopping_list_screen.dart';
import 'package:plan_chef/theme/app_theme.dart';
import 'package:plan_chef/widgets/week_plan_creation_dialog.dart';

import '../services/firestore_service.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: const Icon(Icons.restaurant_menu),
          ),
          title: Row(
            children: [
              const Text('Plan '),
              const Text('Chef'),
              const SizedBox(width: 8),
              const Icon(Icons.eco),
            ],
          ),
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
          HomeScreen(),
          const RecipesScreen(),
          const MenuGeneratorScreen(),
          const ShoppingListScreen(),
        ][_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recetas'),
          ],
        ),
      ),
    );
  }
}
