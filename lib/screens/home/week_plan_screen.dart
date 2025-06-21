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
    // Define weekDays for use in the widget
    final weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
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
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar plan de semana',
            onPressed: _weekPlan == null
                ? null
                : () async {
                    final allMealOptions = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
                    final currentMeals = _weekPlan!.days.isNotEmpty
                        ? _weekPlan!.days.first.meals.keys.toSet()
                        : allMealOptions.toSet();
                    final weekDays = [
                      'Lunes',
                      'Martes',
                      'Miércoles',
                      'Jueves',
                      'Viernes',
                      'Sábado',
                      'Domingo'
                    ];
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => WeekPlanCreationDialog(
                        initialMeals: currentMeals,
                        mealOptions: allMealOptions,
                        initialStartDate: _weekPlan!.startDate,
                        initialEndDate: _weekPlan!.endDate,
                      ),
                    );
                    if (result == null) return;
                    final selectedMealTypes = List<String>.from(result['meals'] as List);
                    final startDate = result['startDate'] as String? ?? 'Lunes';
                    final endDate = result['endDate'] as String? ?? 'Domingo';
                    int startIdx = weekDays.indexOf(startDate);
                    int endIdx = weekDays.indexOf(endDate);
                    int numDays = startIdx <= endIdx
                        ? endIdx - startIdx + 1
                        : (weekDays.length - startIdx) + endIdx + 1;
                    // Build new days list, preserving meal assignments where possible
                    final oldDaysByWeekday = {
                      for (var d in _weekPlan!.days) weekDays[int.tryParse(d.id) ?? 0]: d
                    };
                    final newDaysList = List.generate(numDays, (i) {
                      int dayIdx = (startIdx + i) % weekDays.length;
                      String weekday = weekDays[dayIdx];
                      final oldDay = oldDaysByWeekday[weekday];
                      // If oldDay exists, preserve meal assignments for matching meal types
                      if (oldDay != null) {
                        final preservedMeals = <String, String>{};
                        for (var meal in selectedMealTypes) {
                          if (oldDay.meals.containsKey(meal)) {
                            preservedMeals[meal] = oldDay.meals[meal]!;
                          } else {
                            preservedMeals[meal] = '';
                          }
                        }
                        return oldDay.copyWith(meals: preservedMeals);
                      } else {
                        return DayPlan(
                          id: dayIdx.toString(),
                          meals: {for (var m in selectedMealTypes) m: ''},
                        );
                      }
                    });
                    setState(() {
                      _weekPlan = WeekPlan(
                        id: _weekPlan!.id,
                        householdId: _weekPlan!.householdId,
                        createdBy: _weekPlan!.createdBy,
                        weekNumber: _weekPlan!.weekNumber,
                        year: _weekPlan!.year,
                        days: newDaysList,
                        createdAt: _weekPlan!.createdAt,
                        startDate: startDate,
                        endDate: endDate,
                      );
                    });
                    await ref
                        .read(firestoreServiceProvider)
                        .updateWeekPlan(_weekPlan!.id!, _weekPlan!);
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide.none,
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide.none,
                                  ),
                                  // Show the actual day of the week instead of 'Día 1'
                                  title: Text(weekDays[
                                      (weekDays.indexOf(_weekPlan!.startDate) + dayIdx) %
                                          weekDays.length]),
                                  initiallyExpanded: true,
                                  children: [
                                    ...['Desayuno', 'Comida', 'Merienda', 'Cena']
                                        .where((mealType) => day.meals.containsKey(mealType))
                                        .map((mealType) {
                                      final recipeId = day.meals[mealType] ?? '';
                                      return FutureBuilder<Recipe?>(
                                        future: recipeId.isNotEmpty
                                            ? _fetchRecipe(recipeId)
                                            : Future.value(null),
                                        builder: (context, snapshot) {
                                          String recipeTitle = '';
                                          if (recipeId.isEmpty) {
                                            recipeTitle = 'Sin asignar';
                                          } else if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            recipeTitle = 'Cargando...';
                                          } else if (!snapshot.hasData || snapshot.data == null) {
                                            recipeTitle = 'Receta no encontrada';
                                          } else {
                                            recipeTitle = snapshot.data!.title;
                                          }
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.lightGreen.withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(color: Colors.lightGreen.shade100),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                              leading: Icon(Icons.restaurant_menu,
                                                  color: Colors.lightGreen.shade300),
                                              title: Text('$mealType: $recipeTitle',
                                                  style:
                                                      const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: recipeId.isNotEmpty &&
                                                      snapshot.hasData &&
                                                      snapshot.data != null
                                                  ? Text(snapshot.data!.ingredients.join(', '),
                                                      style: const TextStyle(fontSize: 13))
                                                  : null,
                                              trailing: IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.lightGreen),
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
                                            ),
                                          );
                                        },
                                      );
                                    }),
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
}
