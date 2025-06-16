import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/models/day_plan.dart';
import 'package:plan_chef/models/week_plan.dart';
import 'package:plan_chef/widgets/week_plan_creation_dialog.dart';

import '../../models/recipe.dart';
import '../../services/firestore_service.dart';
import '../../services/household_provider.dart';

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
        actions: [
          // TEMP: Migration button for admin/dev use
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(firebaseUserProvider).asData?.value;
              final householdIdAsync = ref.watch(householdIdProvider);
              return householdIdAsync.when(
                data: (householdId) => IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Migrar weekPlans',
                  onPressed: user == null || householdId == null
                      ? null
                      : () async {
                          final batch = FirebaseFirestore.instance.batch();
                          final query = await FirebaseFirestore.instance
                              .collection('weekPlans')
                              .where('createdBy', isEqualTo: user.uid)
                              .get();
                          int updated = 0;
                          for (var doc in query.docs) {
                            if ((doc.data()['householdId'] ?? '').isEmpty) {
                              batch.update(doc.reference, {'householdId': householdId});
                              updated++;
                            }
                          }
                          if (updated > 0) {
                            await batch.commit();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('WeekPlans migrados: $updated')),
                          );
                        },
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              );
            },
          ),
        ],
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
                                        subtitle: FutureBuilder<Recipe?>(
                                          future: recipeId.isNotEmpty
                                              ? _fetchRecipe(recipeId)
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
                                            final title = recipe.title;
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
    final householdId = await ref.read(householdIdProvider.future);
    if (user == null || householdId == null) return;

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
        householdId: householdId, // use real householdId
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
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) return null;
    // Only show recipes that include the selected mealType
    final recipes = (await FirebaseFirestore.instance
            .collection('recipes')
            .where('householdId', isEqualTo: householdId)
            .get())
        .docs
        .map((doc) => Recipe.fromFirestore(doc))
        .where((r) => r.mealTypes.contains(mealType))
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 2),
                            child: Text(
                              recipe.mealTypes.join(', '),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          RadioListTile<String>(
                            title: Text(recipe.title),
                            value: recipe.id,
                            groupValue: selectedRecipeId,
                            onChanged: (val) {
                              selectedRecipeId = val;
                              Navigator.of(context).pop(val);
                            },
                          ),
                        ],
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

  Future<Recipe?> _fetchRecipe(String recipeId) async {
    final doc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
    if (!doc.exists) return null;
    return Recipe.fromFirestore(doc);
  }

  int _getWeekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final thursday = date.add(Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final daysDifference = thursday.difference(firstDayOfYear).inDays;
    return 1 + (daysDifference / 7).floor();
  }
}
