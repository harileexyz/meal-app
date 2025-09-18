import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:meal_app/ui/details/recipie_detail_screen.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../repositories/recipe_repository.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_logger.dart';
import '../components/recipe_card_list_tile.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.title});

  final String title;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final RecipeRepository _repository = RecipeRepository();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Recipe> _searchResults = const [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounce;
  final Set<String> _savingRecipeIds = <String>{};
  final Map<String, bool> _expectedSavedStates = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_controller.text);
    });
  }

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

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = const [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _repository.searchRecipes(trimmed, limit: 40);
      setState(() {
        _searchResults = results;
      });
    } catch (error, stack) {
      AppLogger.i
          .e('Search failed for "$trimmed"', error: error, stackTrace: stack);
      setState(() {
        _searchError = 'Could not search recipes. Please try again.';
        _searchResults = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore;
    try {
      homeStore = context.read<HomeStore>();
    } catch (error, stack) {
      AppLogger.i.e(
        'DetailsScreen requires HomeStore in the widget tree',
        error: error,
        stackTrace: stack,
      );
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('Could not load recipes.'),
        ),
      );
    }

    final savedIds = homeStore.savedRecipeIds;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search recipes',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _controller.text.trim().isNotEmpty
                  ? _buildSearchResults(context, homeStore, savedIds.toSet())
                  : _buildContentList(context, homeStore, savedIds.toSet()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    HomeStore homeStore,
    Set<String> savedIds,
  ) {
    if (_isSearching) {
      return const _CenteredLoader();
    }

    if (_searchError != null) {
      return _ErrorNotice(message: _searchError!);
    }

    if (_searchResults.isEmpty) {
      return const _EmptyNotice(message: 'No recipes found for your search.');
    }

    return RefreshIndicator(
      onRefresh: () => _performSearch(_controller.text),
      child: ListView.separated(
        padding: AppTheme.screenPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final recipe = _searchResults[index];
          return RecipeCardListTile(
            recipe: recipe,
            isSaved: savedIds.contains(recipe.id),
            isLoading: _isRecipeLoading(recipe.id, savedIds),
            onToggleSave: () => _handleToggleSave(context, homeStore, recipe),
            onRate: () => _handleRate(context, homeStore, recipe),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Provider<HomeStore>.value(
                    value: homeStore,
                    child: RecipieDetailScreen(recipe: recipe),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContentList(
    BuildContext context,
    HomeStore homeStore,
    Set<String> savedIds,
  ) {
    // Determine which content to show based on title
    final isRecentRecipes = widget.title.toLowerCase().contains('recent');

    return RefreshIndicator(
      onRefresh: homeStore.refresh,
      edgeOffset: 16,
      child: Observer(
        builder: (_) {
          final recipes = isRecentRecipes
              ? homeStore.recentRecipes.toList(growable: false)
              : homeStore.trendingRecipes.toList(growable: false);
          final isLoaded = isRecentRecipes
              ? homeStore.recentLoaded.value
              : homeStore.trendingLoaded.value;
          final error = homeStore.errorMessage.value;

          if (!isLoaded && recipes.isEmpty) {
            return const _CenteredLoader();
          }

          if (error != null && recipes.isEmpty) {
            return _ErrorNotice(message: error);
          }

          if (recipes.isEmpty) {
            final emptyMessage = isRecentRecipes
                ? 'No recent recipes yet.'
                : 'No trending recipes yet.';
            return _EmptyNotice(message: emptyMessage);
          }

          return ListView.separated(
            padding: AppTheme.screenPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCardListTile(
                recipe: recipe,
                isSaved: savedIds.contains(recipe.id),
                isLoading: _isRecipeLoading(recipe.id, savedIds),
                onToggleSave: () =>
                    _handleToggleSave(context, homeStore, recipe),
                onRate: () => _handleRate(context, homeStore, recipe),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Provider<HomeStore>.value(
                        value: homeStore,
                        child: RecipieDetailScreen(recipe: recipe),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleToggleSave(
    BuildContext context,
    HomeStore homeStore,
    Recipe recipe,
  ) async {
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
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasSaved
                  ? '${recipe.name} removed from saved'
                  : '${recipe.name} added to saved',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on StateError catch (_) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to save recipes.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Remove loading state on error
      if (mounted) {
        setState(() {
          _savingRecipeIds.remove(recipe.id);
          _expectedSavedStates.remove(recipe.id);
        });
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
      if (mounted) {
        setState(() {
          _savingRecipeIds.remove(recipe.id);
          _expectedSavedStates.remove(recipe.id);
        });
      }
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

      await homeStore.rateRecipe(recipe, result);
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for rating!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on StateError catch (_) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to rate recipes.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit rating.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          'Could not load recipes.\n$message',
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
