import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/week_plan.dart';
import '../services/firestore_service.dart';

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
                        // TODO: Optionally navigate to week plan details
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
