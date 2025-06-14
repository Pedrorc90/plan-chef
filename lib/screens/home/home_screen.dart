import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plan_chef/models/day_plan.dart';
import 'package:plan_chef/models/week_plan.dart';
import 'package:plan_chef/widgets/week_plan_creation_dialog.dart';

import '../../services/firestore_service.dart';

import 'week_plan_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onGenerateMenu;
  const HomeScreen({super.key, this.onGenerateMenu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekPlansAsync = ref.watch(weekPlansProvider);
    final userAsync = ref.watch(firebaseUserProvider);
    if (userAsync.value == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }
    return Scaffold(
      body: weekPlansAsync.when(
        data: (weekPlans) => weekPlans.isEmpty
            ? const Center(child: Text('No hay planes de semana.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: weekPlans.length,
                itemBuilder: (context, index) {
                  final plan = weekPlans[index];
                  return Card(
                    child: ListTile(
                      title: Text('Semana ${plan.weekNumber} - ${plan.year}'),
                      subtitle: Text('Días: ${plan.days.length}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WeekPlanScreen(weekPlanId: plan.id!),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = ref.read(firebaseUserProvider).asData?.value;
          if (user == null) return;
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
          final now = DateTime.now();
          final weekNumber = _getWeekNumber(now);
          final year = now.year;
          final days = List.generate(
            selectedNumDays,
            (i) => DayPlan(id: i.toString(), meals: {for (var m in selectedMealTypes) m: ''}),
          );
          final newPlan = WeekPlan(
            id: null,
            createdBy: user.uid,
            weekNumber: weekNumber,
            year: year,
            days: days,
            createdAt: now,
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
}
