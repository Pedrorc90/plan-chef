import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  Future<void> _addRecipe(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: user == null ? null : () => _addRecipe(context),
            tooltip: 'Agregar receta',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('createdBy', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay recetas aún.'));
          }
          final recipes = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final doc = recipes[index];
              final recipe = doc.data() as Map<String, dynamic>;
              return Dismissible(
                key: Key(doc.id),
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
                  await FirebaseFirestore.instance.collection('recipes').doc(doc.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Receta eliminada')),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Text(recipe['title'] ?? ''),
                    subtitle: Text((recipe['ingredients'] as List<dynamic>?)?.join(', ') ?? ''),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
