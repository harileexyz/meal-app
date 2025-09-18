import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../stores/home_store.dart';
import '../details/details_screen.dart';
import 'recipe_card_list_tile.dart';

class TrendingRecipes extends StatefulWidget {
  const TrendingRecipes({super.key});

  @override
  State<TrendingRecipes> createState() => _TrendingRecipesState();
}

class _TrendingRecipesState extends State<TrendingRecipes> {
  final Set<String> _savingRecipeIds = <String>{};
  final Map<String, bool> _expectedSavedStates = <String, bool>{};

  bool _isRecipeLoading(String recipeId, Set<String> savedIds) {
    if (!_savingRecipeIds.contains(recipeId)) return false;

    final expectedState = _expectedSavedStates[recipeId];
    if (expectedState == null) return false;

    final actualState = savedIds.contains(recipeId);

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
  Widget build(BuildContext context) {
    final homeStore = context.read<HomeStore>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Trending now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text('🔥', style: TextStyle(fontSize: 18)),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Provider<HomeStore>.value(
                      value: homeStore,
                      child: const DetailsScreen(title: 'Trending Recipies'),
                    ),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFE23E3E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Observer(
            builder: (_) {
              final recipes = homeStore.trendingRecipes;
              final isLoaded = homeStore.trendingLoaded.value;
              final error = homeStore.errorMessage.value;

              if (!isLoaded && recipes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (error != null && recipes.isEmpty) {
                return Center(
                  child: Text(
                    'Could not load trending recipes',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (recipes.isEmpty) {
                return const Center(child: Text('No trending recipes yet.'));
              }

              final savedIds = homeStore.savedRecipeIds.toSet();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final isSaved = savedIds.contains(recipe.id);

                  return RecipeCardListTile(
                    recipe: recipe,
                    isSaved: isSaved,
                    isLoading: _isRecipeLoading(recipe.id, savedIds),
                    isHorizontal: true,
                    onToggleSave: () => _toggleSave(homeStore, recipe),
                    onRate: () => _openRatingSheet(homeStore, recipe),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSave(HomeStore homeStore, Recipe recipe) async {
    if (!homeStore.isSignedIn) {
      _showSnackBar('Sign in to save recipes.');
      return;
    }

    // Check the current state before toggling to determine the action
    final wasSaved = homeStore.isRecipeSaved(recipe.id);
    final expectedState = !wasSaved;

    // Add to loading set and track expected state
    setState(() {
      _savingRecipeIds.add(recipe.id);
      _expectedSavedStates[recipe.id] = expectedState;
    });

    try {
      await homeStore.toggleSave(recipe);
      _showSnackBar(
        wasSaved
            ? '${recipe.name} removed from saved'
            : '${recipe.name} added to saved',
      );
    } on StateError catch (_) {
      _showSnackBar('Sign in to save recipes.');
      // Remove loading state on error
      setState(() {
        _savingRecipeIds.remove(recipe.id);
        _expectedSavedStates.remove(recipe.id);
      });
    } catch (error) {
      _showSnackBar('Could not update saved recipes.');
      // Remove loading state on error
      setState(() {
        _savingRecipeIds.remove(recipe.id);
        _expectedSavedStates.remove(recipe.id);
      });
    }
  }

  Future<void> _openRatingSheet(HomeStore homeStore, Recipe recipe) async {
    if (!homeStore.isSignedIn) {
      _showSnackBar('Sign in to rate recipes.');
      return;
    }

    final existingRating = await homeStore.getUserRating(recipe.id);

    var selectedRating = existingRating ??
        (recipe.ratingSummary.average == 0
            ? 4.0
            : recipe.ratingSummary.average.clamp(1.0, 5.0));

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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selectedRating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: selectedRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        selectedRating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selectedRating),
                    child: const Text('Submit rating'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await homeStore.rateRecipe(recipe, result);
      _showSnackBar('Thanks for rating!');
    } catch (error) {
      _showSnackBar('Could not submit rating.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
