import 'dart:async';

import 'package:mobx/mobx.dart';

import '../models/category.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../utils/app_logger.dart';

class HomeStore {
  HomeStore(this._repository);

  final RecipeRepository _repository;

  final ObservableList<Recipe> trendingRecipes = ObservableList<Recipe>();
  final ObservableList<Recipe> recentRecipes = ObservableList<Recipe>();
  final ObservableList<Category> categories = ObservableList<Category>();
  final ObservableSet<String> savedRecipeIds = ObservableSet<String>();

  final Observable<bool> trendingLoaded = Observable(false);
  final Observable<bool> recentLoaded = Observable(false);
  final Observable<bool> categoriesLoaded = Observable(false);
  final Observable<bool> isRefreshing = Observable(false);
  final Observable<String?> errorMessage = Observable(null);
  final Observable<String?> selectedCategorySlug = Observable(null);

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<Set<String>>? _savedSubscription;
  bool _initialized = false;
  String? _userId;

  void init({required String? userId}) {
    if (_initialized) {
      updateUser(userId);
      return;
    }

    _initialized = true;
    updateUser(userId);
    _listenTrendingRecipes();
    _listenRecentRecipes();
    _listenCategories();
  }

  void updateUser(String? userId) {
    _userId = userId;
    _savedSubscription?.cancel();

    if (userId == null || userId.isEmpty) {
      runInAction(() {
        savedRecipeIds.clear();
      });
      return;
    }

    _savedSubscription = _repository.watchSavedRecipeIds(userId).listen(
      (ids) {
        runInAction(() {
          savedRecipeIds
            ..clear()
            ..addAll(ids);
        });
      },
      onError: _handleError,
    );
  }

  bool isRecipeSaved(String recipeId) => savedRecipeIds.contains(recipeId);

  bool get isSignedIn => _userId != null && _userId!.isNotEmpty;

  void setSelectedCategory(String slug) {
    runInAction(() {
      selectedCategorySlug.value = slug;
    });
  }

  Future<void> refresh() async {
    if (isRefreshing.value) {
      return;
    }

    runInAction(() {
      isRefreshing.value = true;
      errorMessage.value = null;
    });

    try {
      await _repository.refreshHomeData();
    } catch (error, stack) {
      _handleError(error, stack);
    } finally {
      runInAction(() {
        isRefreshing.value = false;
      });
    }
  }

  Future<void> toggleSave(Recipe recipe) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('auth-required');
    }

    try {
      await _repository.toggleSaveRecipe(userId: userId, recipeId: recipe.id);
    } catch (error, stack) {
      _handleError(error, stack);
      rethrow;
    }
  }

  Future<void> rateRecipe(Recipe recipe, double rating) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('auth-required');
    }

    try {
      await _repository.rateRecipe(
        userId: userId,
        recipeId: recipe.id,
        rating: rating,
      );
    } catch (error, stack) {
      _handleError(error, stack);
      rethrow;
    }
  }

  Future<double?> getUserRating(String recipeId) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    try {
      return await _repository
          .watchUserRating(userId: userId, recipeId: recipeId)
          .first;
    } catch (error, stack) {
      _handleError(error, stack);
      return null;
    }
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _savedSubscription?.cancel();
  }

  void _listenTrendingRecipes() {
    final sub = _repository.watchTrendingRecipes(limit: 10).listen(
      (recipes) {
        runInAction(() {
          trendingRecipes
            ..clear()
            ..addAll(recipes);
          trendingLoaded.value = true;
        });
      },
      onError: _handleError,
    );
    _subscriptions.add(sub);
  }

  void _listenRecentRecipes() {
    final sub = _repository.watchRecentRecipes(limit: 12).listen(
      (recipes) {
        runInAction(() {
          recentRecipes
            ..clear()
            ..addAll(recipes);
          recentLoaded.value = true;
        });
      },
      onError: _handleError,
    );
    _subscriptions.add(sub);
  }

  void _listenCategories() {
    final sub = _repository.watchCategories(limit: 12).listen(
      (items) {
        runInAction(() {
          final incoming = items.toList(growable: false);
          categories
            ..clear()
            ..addAll(incoming);
          categoriesLoaded.value = true;

          final currentSlug = selectedCategorySlug.value;
          final hasCurrent = currentSlug != null &&
              incoming.any((category) => category.slug == currentSlug);

          if (!hasCurrent) {
            String? fallback;
            for (final category in incoming) {
              if (category.slug.toLowerCase() == 'breakfast') {
                fallback = category.slug;
                break;
              }
            }
            fallback ??= incoming.isNotEmpty ? incoming.first.slug : null;
            selectedCategorySlug.value = fallback;
          }
        });
      },
      onError: _handleError,
    );
    _subscriptions.add(sub);
  }

  void _handleError(Object error, StackTrace stack) {
    AppLogger.i.e('HomeStore error', error: error, stackTrace: stack);
    runInAction(() {
      errorMessage.value = error.toString();
    });
  }
}
