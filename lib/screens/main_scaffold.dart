import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/screens/home/home_screen.dart';
import 'package:plan_chef/screens/home/shopping_list_screen.dart';
import 'package:plan_chef/screens/profile/profile_screen.dart';
import 'package:plan_chef/screens/recipes/recipes_screen.dart';
import 'package:plan_chef/theme/app_theme.dart';

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
          centerTitle: true,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu),
              SizedBox(width: 8),
              Text('Plan '),
              Text('Chef'),
              SizedBox(width: 8),
              Icon(Icons.eco),
            ],
          ),
          actions: const [], // Removed the logout button from the AppBar actions
        ),
        body: [
          const HomeScreen(),
          const RecipesScreen(),
          //const MenuGeneratorScreen(),
          const ShoppingListScreen(),
          const ProfileScreen(),
        ][_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recetas'),
            //BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Menú'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
