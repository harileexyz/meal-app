import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_logger.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore;
    try {
      homeStore = context.read<HomeStore>();
    } catch (error, stack) {
      AppLogger.i.e(
        'TrendingScreen requires HomeStore in the widget tree',
        error: error,
        stackTrace: stack,
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Trending recipes')),
        body: const Center(
          child: Text('Could not load trending recipes.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text('Trending recipes'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: homeStore.refresh,
          edgeOffset: 16,
          child: Observer(
            builder: (_) {
              final recipes = homeStore.trendingRecipes.toList(growable: false);
              final isLoaded = homeStore.trendingLoaded.value;
              final error = homeStore.errorMessage.value;

              if (!isLoaded && recipes.isEmpty) {
                return const _CenteredLoader();
              }

              if (error != null && recipes.isEmpty) {
                return _ErrorNotice(message: error);
              }

              if (recipes.isEmpty) {
                return const _EmptyNotice(message: 'No trending recipes yet.');
              }

              final savedIds = homeStore.savedRecipeIds.toSet();

              return ListView.separated(
                padding: AppTheme.screenPadding,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final isSaved = savedIds.contains(recipe.id);

                  return _TrendingListTile(
                    recipe: recipe,
                    isSaved: isSaved,
                    onToggleSave: () =>
                        _handleToggleSave(context, homeStore, recipe),
                    onRate: () => _handleRate(context, homeStore, recipe),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleToggleSave(
    BuildContext context,
    HomeStore homeStore,
    Recipe recipe,
  ) async {
    try {
      await homeStore.toggleSave(recipe);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            homeStore.isRecipeSaved(recipe.id)
                ? '${recipe.name} added to saved'
                : '${recipe.name} removed from saved',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save recipes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update saved recipes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRate(
    BuildContext context,
    HomeStore homeStore,
    Recipe recipe,
  ) async {
    try {
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

      await homeStore.rateRecipe(recipe, result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for rating!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to rate recipes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit rating.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TrendingListTile extends StatelessWidget {
  const _TrendingListTile({
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: recipe.primaryImage.isNotEmpty
                ? Ink.image(
                    image: NetworkImage(recipe.primaryImage),
                    fit: BoxFit.cover,
                    child: InkWell(onTap: onRate),
                  )
                : InkWell(
                    onTap: onRate,
                    child: Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant_menu, size: 36),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleSave,
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.description.isNotEmpty
                      ? recipe.description
                      : 'By ${recipe.authorDisplay}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(recipe.ratingSummary.average.toStringAsFixed(1)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 4),
                    Text(recipe.timeLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Text(
          'Could not load trending recipes.\n$message',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
