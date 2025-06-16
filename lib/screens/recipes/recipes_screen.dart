import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../../services/firestore_service.dart';
import '../../services/household_provider.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  Future<void> _addRecipe(BuildContext context, WidgetRef ref) async {
    final user = ref.read(firebaseUserProvider).asData?.value;
    if (user == null) return;
    // Get householdId from provider
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes un hogar vinculado.')),
      );
      return;
    }
    final titleController = TextEditingController();
    final ingredientsController = TextEditingController();
    final mealTypes = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
    final selectedMealTypes = <String>{};
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar receta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(labelText: 'Ingredientes (separados por coma)'),
              ),
              const SizedBox(height: 16),
              const Text('Tipo de receta:'),
              ...mealTypes.map((type) => CheckboxListTile(
                    title: Text(type),
                    value: selectedMealTypes.contains(type),
                    onChanged: (checked) {
                      (dialogContext as Element).markNeedsBuild();
                      if (checked == true) {
                        selectedMealTypes.add(type);
                      } else {
                        selectedMealTypes.remove(type);
                      }
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final ingredients =
                  ingredientsController.text.split(',').map((e) => e.trim()).toList();
              if (title.isNotEmpty && selectedMealTypes.isNotEmpty) {
                await FirebaseFirestore.instance.collection('recipes').add({
                  'title': title,
                  'ingredients': ingredients,
                  'createdBy': user.uid,
                  'householdId': householdId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'mealTypes': selectedMealTypes.toList(),
                });
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Color _mealTypeColor(String mealType) {
    switch (mealType) {
      case 'Desayuno':
        return Colors.orange.shade200;
      case 'Comida':
        return Colors.green.shade200;
      case 'Merienda':
        return Colors.blue.shade200;
      case 'Cena':
        return Colors.purple.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseUserProvider).asData?.value;
    final householdIdAsync = ref.watch(householdIdProvider);
    return Scaffold(
      body: householdIdAsync.when(
        data: (householdId) {
          if (householdId == null) {
            return const Center(child: Text('No tienes un hogar vinculado.'));
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recipes')
                .where('householdId', isEqualTo: householdId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay recetas aún.'));
              }
              final recipes = snapshot.data!.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Dismissible(
                    key: Key(recipe.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar receta'),
                          content: const Text('¿Estás seguro de que deseas eliminar esta receta?'),
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
                      await FirebaseFirestore.instance
                          .collection('recipes')
                          .doc(recipe.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receta eliminada')),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(recipe.title)),
                            Row(
                              children: recipe.mealTypes
                                  .map((type) => Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _mealTypeColor(type),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        subtitle: Text(recipe.ingredients.join(', ')),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              onPressed: () => _addRecipe(context, ref),
              tooltip: 'Agregar receta',
              child: const Icon(Icons.add),
            ),
    );
  }
}
