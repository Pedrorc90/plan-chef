import 'package:flutter/material.dart';

class WeekPlanCreationDialog extends StatefulWidget {
  final int initialDays;
  final Set<String> initialMeals;
  final List<String> mealOptions;
  final String initialStartDate;
  final String initialEndDate;

  const WeekPlanCreationDialog({
    super.key,
    this.initialDays = 7,
    required this.initialMeals,
    required this.mealOptions,
    this.initialStartDate = 'Lunes',
    this.initialEndDate = 'Domingo',
  });

  @override
  State<WeekPlanCreationDialog> createState() => _WeekPlanCreationDialogState();
}

class _WeekPlanCreationDialogState extends State<WeekPlanCreationDialog> {
  late int tempDays;
  late Set<String> tempMeals;
  late String tempStartDate;
  late String tempEndDate;

  final List<String> weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    tempDays = widget.initialDays;
    tempMeals = Set<String>.from(widget.initialMeals);
    tempStartDate = widget.initialStartDate;
    tempEndDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo plan de semana'),
      content: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Día de inicio: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: tempStartDate,
                  items: weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => tempStartDate = v);
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('Día de fin: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: tempEndDate,
                  items: weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => tempEndDate = v);
                  },
                ),
              ],
            ),
          ],
        ),
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
              'startDate': tempStartDate,
              'endDate': tempEndDate,
            });
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
