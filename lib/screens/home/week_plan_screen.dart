import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/models/day_plan.dart';
import 'package:plan_chef/models/week_plan.dart';
import 'package:plan_chef/widgets/week_plan_creation_dialog.dart';

import '../../services/firestore_service.dart';

class WeekPlanScreen extends ConsumerStatefulWidget {
  final String weekPlanId;
  const WeekPlanScreen({super.key, required this.weekPlanId});

  @override
  ConsumerState<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends ConsumerState<WeekPlanScreen> {
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
      final user = ref.read(firebaseUserProvider).asData?.value;
      if (user == null) throw Exception('No user');
      final plan = await ref.read(firestoreServiceProvider).getWeekPlanById(widget.weekPlanId);
      setState(() {
        _weekPlan = plan;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Semana'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _weekPlan == null
                  ? const Center(child: Text('No hay plan de semana.'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
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
                                              ? ref
                                                  .read(firestoreServiceProvider)
                                                  .fetchRecipeById(recipeId)
                                              : Future.value(null),
                                          builder: (context, snapshot) {
                                            if (recipeId.isEmpty) {
                                              return const Text('Sin asignar');
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
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
                                            final selectedRecipeId =
                                                await _selectRecipeDialog(mealType);
                                            if (selectedRecipeId != null) {
                                              setState(() {
                                                day.meals[mealType] = selectedRecipeId;
                                              });
                                              await ref
                                                  .read(firestoreServiceProvider)
                                                  .updateWeekPlan(_weekPlan!.id!, _weekPlan!);
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
                    ),
    );
  }

  Future<void> _createNewWeekPlan() async {
    final user = ref.read(firebaseUserProvider).asData?.value;
    if (user == null) return;

    // Show modal to select days and meal types
    int selectedDays = 7;
    final mealOptions = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
    final selectedMeals = mealOptions.toSet();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WeekPlanCreationDialog(
        initialDays: selectedDays,
        initialMeals: selectedMeals,
        mealOptions: mealOptions,
      ),
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
        id: null, // Firestore will assign the ID
        createdBy: user.uid,
        weekNumber: weekNumber,
        year: year,
        days: days,
        createdAt: now,
      );
      await ref.read(firestoreServiceProvider).createWeekPlan(newPlan);
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
    final user = ref.read(firebaseUserProvider).asData?.value;
    if (user == null) return null;
    // Only show recipes that include the selected mealType
    final recipes = (await ref.read(firestoreServiceProvider).fetchRecipes(user.uid))
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
