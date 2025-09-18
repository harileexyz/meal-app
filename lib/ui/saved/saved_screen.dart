import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../repositories/recipe_repository.dart';
import '../../theme/app_theme.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final RecipeRepository _repository = RecipeRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Center(
            child: Text('Sign in to save your favourite recipes.'),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved recipes',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: _repository.watchSavedRecipes(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load saved recipes',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  }

                  final recipes = snapshot.data ?? <Recipe>[];
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Your saved recipes will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      final time = recipe.timeLabel;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: recipe.primaryImage.isNotEmpty
                                ? Image.network(
                                    recipe.primaryImage,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.restaurant_menu),
                                  ),
                          ),
                          title: Text(
                            recipe.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('By ${recipe.authorDisplay}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(recipe.ratingSummary.average.toStringAsFixed(1)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.schedule, size: 14),
                                  const SizedBox(width: 4),
                                  Text(time),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () => _toggleSave(user.uid, recipe),
                            icon: const Icon(Icons.bookmark),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave(String userId, Recipe recipe) async {
    try {
      await _repository.toggleSaveRecipe(userId: userId, recipeId: recipe.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} removed from saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update saved recipes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
