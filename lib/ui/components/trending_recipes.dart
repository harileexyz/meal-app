import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../stores/home_store.dart';
import '../trending/trending_screen.dart';

class TrendingRecipes extends StatefulWidget {
  const TrendingRecipes({super.key});

  @override
  State<TrendingRecipes> createState() => _TrendingRecipesState();
}

class _TrendingRecipesState extends State<TrendingRecipes> {
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
                      child: const TrendingScreen(),
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

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RecipeCard(
                          recipe: recipe,
                          isSaved: isSaved,
                          onToggleSave: () => _toggleSave(homeStore, recipe),
                          onRate: () => _openRatingSheet(homeStore, recipe),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: recipe.author.avatarUrl != null
                                  ? NetworkImage(recipe.author.avatarUrl!)
                                  : null,
                              child: recipe.author.avatarUrl == null
                                  ? Text(
                                      recipe.author.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                recipe.authorDisplay,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

    try {
      await homeStore.toggleSave(recipe);
    } catch (error) {
      _showSnackBar('Could not update saved recipes.');
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

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.isSaved,
    required this.onToggleSave,
    required this.onRate,
  });

  final Recipe recipe;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            recipe.primaryImage.isNotEmpty
                ? Image.network(
                    recipe.primaryImage,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu, size: 32),
                  ),
            Positioned(
              top: 8,
              left: 8,
              child: InkWell(
                onTap: onRate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        recipe.ratingSummary.average.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: onToggleSave,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe.timeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
