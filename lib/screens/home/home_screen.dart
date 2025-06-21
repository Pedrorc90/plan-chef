import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:plan_chef/models/day_plan.dart';
import 'package:plan_chef/models/week_plan.dart';
import 'package:plan_chef/widgets/week_plan_creation_dialog.dart';

import '../../services/firestore_service.dart';
import '../../services/household_provider.dart';

import 'week_plan_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onGenerateMenu;
  const HomeScreen({super.key, this.onGenerateMenu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekPlansAsync = ref.watch(weekPlansProvider);
    final userAsync = ref.watch(firebaseUserProvider);
    final householdIdAsync = ref.watch(householdIdProvider);
    if (userAsync.value == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }
    return Scaffold(
      body: householdIdAsync.when(
        data: (householdId) {
          return weekPlansAsync.when(
            data: (weekPlans) => weekPlans.isEmpty
                ? const Center(child: Text('No hay planes de semana.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: weekPlans.length,
                    itemBuilder: (context, index) {
                      final plan = weekPlans[index];
                      return Dismissible(
                        key: Key(plan.id!),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12), // Match Card's border radius
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar plan de semana'),
                              content: const Text(
                                  '¿Estás seguro de que deseas eliminar este plan de semana?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await ref.read(firestoreServiceProvider).deleteWeekPlan(plan.id!);
                          ref.invalidate(weekPlansProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plan de semana eliminado')),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            title: Text('Menú desde '
                                '${plan.startDate} '
                                '${_formatDate(plan.createdAt, plan.startDate, plan.days.length)}'
                                ' hasta '
                                '${plan.endDate} '
                                '${_formatDate(plan.createdAt, plan.endDate, plan.days.length, isEnd: true)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //Text('Días: ${plan.days.length}'),
                                if (plan.days.isNotEmpty)
                                  Text(
                                    plan.days.first.meals.keys.join(', '),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => WeekPlanScreen(weekPlanId: plan.id!),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: householdIdAsync.value == null || userAsync.value == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                int selectedDays = 7;
                final mealOptions = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
                final selectedMeals = mealOptions.toSet();
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => WeekPlanCreationDialog(
                    initialDays: selectedDays,
                    initialMeals: selectedMeals,
                    mealOptions: mealOptions,
                    // New fields for start/end date
                    initialStartDate: 'Lunes',
                    initialEndDate: 'Domingo',
                  ),
                );
                if (result == null) return;
                final selectedNumDays = result['days'] as int;
                final selectedMealTypes = List<String>.from(result['meals'] as List);
                final startDate = result['startDate'] as String? ?? 'Lunes';
                final endDate = result['endDate'] as String? ?? 'Domingo';
                final numDays = _daysBetweenWeekdays(startDate, endDate);
                final now = DateTime.now();
                final weekNumber = _getWeekNumber(now);
                final year = now.year;
                final days = List.generate(
                  numDays,
                  (i) => DayPlan(id: i.toString(), meals: {for (var m in selectedMealTypes) m: ''}),
                );
                final newPlan = WeekPlan(
                  id: null,
                  householdId: householdIdAsync.value!,
                  createdBy: userAsync.value!.uid,
                  weekNumber: weekNumber,
                  year: year,
                  days: days,
                  createdAt: now,
                  startDate: startDate,
                  endDate: endDate,
                );
                await ref.read(firestoreServiceProvider).createWeekPlan(newPlan);
                ref.invalidate(weekPlansProvider);
              },
              tooltip: 'Crear nuevo plan de semana',
              child: const Icon(Icons.add),
            ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final daysDifference = thursday.difference(firstDayOfYear).inDays;
    return 1 + (daysDifference / 7).floor();
  }

  String _formatDate(DateTime createdAt, String dayName, int numDays, {bool isEnd = false}) {
    // Map day names to weekday numbers (Monday=1, ..., Sunday=7)
    const dayMap = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
      'Sábado': 6,
      'Domingo': 7,
    };
    int startWeekday = dayMap[dayName] ?? 1;
    // Find the first date in the week that matches the start day
    DateTime startDate = createdAt;
    while (startDate.weekday != startWeekday) {
      startDate = startDate.add(const Duration(days: 1));
    }
    if (isEnd) {
      // End date is start date + numDays - 1
      startDate = startDate.add(Duration(days: numDays - 1));
    }
    return DateFormat('dd/MM').format(startDate);
  }

  int _daysBetweenWeekdays(String start, String end) {
    const dayMap = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
      'Sábado': 6,
      'Domingo': 7,
    };
    int startIdx = dayMap[start] ?? 1;
    int endIdx = dayMap[end] ?? 1;
    int diff = endIdx - startIdx;
    if (diff < 0) diff += 7;
    return diff + 1;
  }
}
