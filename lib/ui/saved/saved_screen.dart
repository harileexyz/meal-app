import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../repositories/recipe_repository.dart';
import '../../theme/app_theme.dart';
import '../components/recipe_card_list_tile.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final RecipeRepository _repository = RecipeRepository();
  final Set<String> _savingRecipeIds = <String>{};
  final Map<String, bool> _expectedSavedStates = <String, bool>{};

  bool _isRecipeLoading(String recipeId, List<Recipe> recipes) {
    if (!_savingRecipeIds.contains(recipeId)) return false;

    final expectedState = _expectedSavedStates[recipeId];
    if (expectedState == null) return false;

    final actualState = recipes.any((recipe) => recipe.id == recipeId);

    // If the actual state matches expected state, remove from loading
    if (actualState == expectedState) {
      // Defer the state update to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _savingRecipeIds.remove(recipeId);
            _expectedSavedStates.remove(recipeId);
          });
        }
      });
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    // Clear any stale loading states when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _savingRecipeIds.clear();
          _expectedSavedStates.clear();
        });
      }
    });
  }

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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeCardListTile(
                        recipe: recipe,
                        isSaved: true,
                        isLoading: _isRecipeLoading(recipe.id, recipes),
                        onToggleSave: () => _toggleSave(user.uid, recipe),
                        onRate: () => _handleRate(context, user.uid, recipe),
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
    // Check the current state before toggling to determine the action
    // In saved screen, all recipes are currently saved, so removing them
    final wasSaved = true; // All recipes in saved screen are saved
    final expectedState = false; // After toggle, they should be unsaved

    // Add to loading set and track expected state
    setState(() {
      _savingRecipeIds.add(recipe.id);
      _expectedSavedStates[recipe.id] = expectedState;
    });

    try {
      await _repository.toggleSaveRecipe(userId: userId, recipeId: recipe.id);
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recipe.name} removed from saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update saved recipes.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Remove loading state on error
      setState(() {
        _savingRecipeIds.remove(recipe.id);
        _expectedSavedStates.remove(recipe.id);
      });
    }
  }

  Future<void> _handleRate(
    BuildContext context,
    String userId,
    Recipe recipe,
  ) async {
    try {
      final existingRating = await _repository
          .watchUserRating(userId: userId, recipeId: recipe.id)
          .firstWhere((_) => true, orElse: () => null);

      var selectedRating = existingRating ??
          (recipe.ratingSummary.average == 0
              ? 4.0
              : recipe.ratingSummary.average.clamp(1.0, 5.0));

      if (!mounted) return;
      if (!context.mounted) return;

      final result = await showModalBottomSheet<double>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Rate ${recipe.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: selectedRating,
                      min: 1,
                      max: 5,
                      divisions: 8,
                      label: selectedRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => selectedRating = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(selectedRating),
                      child: const Text('Submit rating'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (result == null) {
        return;
      }

      await _repository.rateRecipe(
        userId: userId,
        recipeId: recipe.id,
        rating: result,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for rating!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to rate recipes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit rating.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
