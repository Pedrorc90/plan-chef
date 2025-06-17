import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../../services/firestore_service.dart';
import '../../services/household_provider.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  Future<void> _showRecipeDialog(BuildContext context, WidgetRef ref, {Recipe? recipe}) async {
    final user = ref.read(firebaseUserProvider).asData?.value;
    if (user == null) return;
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes un hogar vinculado.')),
      );
      return;
    }
    final titleController = TextEditingController(text: recipe?.title ?? '');
    final ingredientsController = TextEditingController(text: recipe?.ingredients.join(', ') ?? '');
    final commentsController = TextEditingController(text: recipe?.comments.join('\n') ?? '');
    final mealTypes = ['Desayuno', 'Comida', 'Merienda', 'Cena'];
    final selectedMealTypes = <String>{...?(recipe?.mealTypes)};
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(recipe == null ? 'Agregar receta' : 'Editar receta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(labelText: 'Ingredientes (separados por coma)'),
              ),
              const SizedBox(height: 16),
              const Text('Tipo de receta:'),
              ...mealTypes.map((type) => StatefulBuilder(
                    builder: (context, setState) => CheckboxListTile(
                      title: Text(type),
                      value: selectedMealTypes.contains(type),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedMealTypes.add(type);
                          } else {
                            selectedMealTypes.remove(type);
                          }
                        });
                      },
                    ),
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios (uno por línea)',
                  alignLabelWithHint: true,
                ),
                minLines: 2,
                maxLines: 5,
              ),
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
              final comments = commentsController.text.trim().isEmpty
                  ? <String>[]
                  : commentsController.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
              if (title.isNotEmpty && selectedMealTypes.isNotEmpty) {
                if (recipe == null) {
                  await FirebaseFirestore.instance.collection('recipes').add({
                    'title': title,
                    'ingredients': ingredients,
                    'createdBy': user.uid,
                    'householdId': householdId,
                    'createdAt': FieldValue.serverTimestamp(),
                    'mealTypes': selectedMealTypes.toList(),
                    'comments': comments,
                  });
                } else {
                  await FirebaseFirestore.instance.collection('recipes').doc(recipe.id).update({
                    'title': title,
                    'ingredients': ingredients,
                    'mealTypes': selectedMealTypes.toList(),
                    'comments': comments,
                  });
                }
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    child: _RecipeCardWithComments(
                        recipe: recipe,
                        onEdit: () => _showRecipeDialog(context, ref, recipe: recipe)),
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
              onPressed: () => _showRecipeDialog(context, ref),
              tooltip: 'Agregar receta',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _RecipeCardWithComments extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onEdit;

  const _RecipeCardWithComments({
    Key? key,
    required this.recipe,
    required this.onEdit,
  }) : super(key: key);

  @override
  __RecipeCardWithCommentsState createState() => __RecipeCardWithCommentsState();
}

class __RecipeCardWithCommentsState extends State<_RecipeCardWithComments> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: widget.onEdit,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 36), // space for the icon
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      recipe.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  ...recipe.mealTypes.map((type) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                      )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.ingredients.join(', '),
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (recipe.comments.isNotEmpty)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: Icon(_expanded ? Icons.comment : Icons.comment_outlined,
                                color: Colors.blueGrey, size: 22),
                            onPressed: () => setState(() => _expanded = !_expanded),
                            tooltip: 'Ver comentarios',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_expanded)
              recipe.comments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin comentarios'),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Comentarios:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...recipe.comments.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('- $c'),
                              )),
                        ],
                      ),
                    ),
          ],
        ),
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
}
