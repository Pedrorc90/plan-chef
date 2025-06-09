import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/week_plan.dart';
import '../services/firestore_service.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  WeekPlan? _weekPlan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeekPlan();
  }

  Future<void> _fetchWeekPlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user');
      final plan = await FirestoreService().fetchCurrentWeekPlan(user.uid);
      setState(() {
        _weekPlan = plan;
        _loading = false;
      });
    } catch (e) {
      print('Error in _fetchWeekPlan:');
      print(e);
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: \\$_error'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear nuevo plan de semana'),
            onPressed: _createNewWeekPlan,
          ),
        ),
        Expanded(
          child: _weekPlan == null
              ? Center(child: Text('No hay plan de semana. Genera uno nuevo.'))
              : ListView.builder(
                  itemCount: _weekPlan!.days.length,
                  itemBuilder: (context, dayIdx) {
                    final day = _weekPlan!.days[dayIdx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text('Día ${dayIdx + 1}'),
                        initiallyExpanded: true,
                        children: [
                          ...day.meals.keys.map((mealType) {
                            final recipeId = day.meals[mealType] ?? '';
                            return ListTile(
                              title: Text(mealType),
                              subtitle: FutureBuilder<Map<String, dynamic>?>(
                                future: recipeId.isNotEmpty
                                    ? FirestoreService().fetchRecipeById(recipeId)
                                    : Future.value(null),
                                builder: (context, snapshot) {
                                  if (recipeId.isEmpty) {
                                    return const Text('Sin asignar');
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Cargando...');
                                  }
                                  if (!snapshot.hasData || snapshot.data == null) {
                                    return const Text('Receta no encontrada');
                                  }
                                  final recipe = snapshot.data!;
                                  final title = recipe['title'] ?? 'Sin nombre';
                                  return Text('Receta: $title');
                                },
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final selectedRecipeId = await _selectRecipeDialog(mealType);
                                  if (selectedRecipeId != null) {
                                    setState(() {
                                      day.meals[mealType] = selectedRecipeId;
                                    });
                                    await FirestoreService()
                                        .updateWeekPlan(_weekPlan!.id, _weekPlan!);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createNewWeekPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show modal to select days and meal types
    int selectedDays = 7;
    final mealOptions = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
    final selectedMeals = mealOptions.toSet();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        int tempDays = selectedDays;
        final tempMeals = Set<String>.from(selectedMeals);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo plan de semana'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Cuántos días?'),
                  Row(
                    children: [
                      Radio<int>(
                        value: 5,
                        groupValue: tempDays,
                        onChanged: (v) => setState(() => tempDays = v ?? 7),
                      ),
                      const Text('5 días'),
                      Radio<int>(
                        value: 7,
                        groupValue: tempDays,
                        onChanged: (v) => setState(() => tempDays = v ?? 7),
                      ),
                      const Text('7 días'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('¿Qué comidas?'),
                  ...mealOptions.map((meal) => CheckboxListTile(
                        title: Text(meal),
                        value: tempMeals.contains(meal),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              tempMeals.add(meal);
                            } else {
                              tempMeals.remove(meal);
                            }
                          });
                        },
                      )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempMeals.isEmpty) return;
                    Navigator.of(context).pop({
                      'days': tempDays,
                      'meals': tempMeals.toList(),
                    });
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null) return;
    final selectedNumDays = result['days'] as int;
    final selectedMealTypes = List<String>.from(result['meals'] as List);

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final weekNumber = _getWeekNumber(now);
      final year = now.year;
      final days = List.generate(
        selectedNumDays,
        (i) => DayPlan(id: i.toString(), meals: {for (var m in selectedMealTypes) m: ''}),
      );
      final newPlan = WeekPlan(
        id: '',
        userId: user.uid,
        weekNumber: weekNumber,
        year: year,
        days: days,
        createdAt: now,
      );
      await FirestoreService().createWeekPlan(newPlan);
      await _fetchWeekPlan();
    } catch (e) {
      print('Error in _createNewWeekPlan:');
      print(e);
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String?> _selectRecipeDialog(String mealType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    // Only show recipes that include the selected mealType
    final recipes = (await FirestoreService().fetchRecipes(user.uid))
        .where((r) => (r['mealTypes'] as List?)?.contains(mealType) ?? false)
        .toList();
    String? selectedRecipeId;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona una receta para $mealType'),
          content: SizedBox(
            width: double.maxFinite,
            child: recipes.isEmpty
                ? const Text('No hay recetas disponibles.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    itemBuilder: (context, idx) {
                      final recipe = recipes[idx];
                      return RadioListTile<String>(
                        title: Text(recipe['title'] ?? 'Sin nombre'),
                        value: recipe['id'],
                        groupValue: selectedRecipeId,
                        onChanged: (val) {
                          selectedRecipeId = val;
                          Navigator.of(context).pop(val);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  int _getWeekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final thursday = date.add(Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final daysDifference = thursday.difference(firstDayOfYear).inDays;
    return 1 + (daysDifference / 7).floor();
  }
}
