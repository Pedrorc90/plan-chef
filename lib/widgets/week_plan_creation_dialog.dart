import 'package:flutter/material.dart';

class WeekPlanCreationDialog extends StatefulWidget {
  final int initialDays;
  final Set<String> initialMeals;
  final List<String> mealOptions;

  const WeekPlanCreationDialog({
    super.key,
    this.initialDays = 7,
    required this.initialMeals,
    required this.mealOptions,
  });

  @override
  State<WeekPlanCreationDialog> createState() => _WeekPlanCreationDialogState();
}

class _WeekPlanCreationDialogState extends State<WeekPlanCreationDialog> {
  late int tempDays;
  late Set<String> tempMeals;

  @override
  void initState() {
    super.initState();
    tempDays = widget.initialDays;
    tempMeals = Set<String>.from(widget.initialMeals);
  }

  @override
  Widget build(BuildContext context) {
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
          ...widget.mealOptions.map((meal) => CheckboxListTile(
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
  }
}
