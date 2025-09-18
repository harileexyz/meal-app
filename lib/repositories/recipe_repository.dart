import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/recipe.dart';
import '../utils/app_logger.dart';

class RecipeRepository {
  RecipeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _recipeCollection =>
      _firestore.collection('recipes');

  CollectionReference<Map<String, dynamic>> _userSavedCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('savedRecipes');

  CollectionReference<Map<String, dynamic>> _userRatingsCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('ratings');

  Stream<List<Recipe>> watchTrendingRecipes({int limit = 10}) {
    final stream = _recipeCollection
        .where('isTrending', isEqualTo: true)
        .orderBy('ratingSummary.average', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final recipes =
              snapshot.docs.map(Recipe.fromDocument).toList(growable: false);
          AppLogger.i.d('Fetched ${recipes.length} trending recipes.');
          return recipes;
        });
    AppLogger.i.d('Subscribed to trending recipes stream (value: $stream.).');
    return stream;
  }

  Stream<List<Recipe>> watchRecentRecipes({int limit = 10}) {
    return _recipeCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Recipe.fromDocument).toList(growable: false));
  }

  Stream<List<Category>> watchCategories({int limit = 10}) {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Category.fromDocument).toList(growable: false));
  }

  Future<List<Recipe>> searchRecipes(String query, {int limit = 20}) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    if (terms.isEmpty) {
      return const <Recipe>[];
    }

    final tokens = terms.length > 10 ? terms.sublist(0, 10) : terms;

    Query<Map<String, dynamic>> ref = _recipeCollection;
    if (tokens.length == 1) {
      ref = ref.where('searchKeywords', arrayContains: tokens.first);
    } else {
      ref = ref.where('searchKeywords', arrayContainsAny: tokens);
    }

    final snapshot = await ref
        .orderBy('ratingSummary.average', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(Recipe.fromDocument).toList(growable: false);
  }

  Stream<Set<String>> watchSavedRecipeIds(String userId) {
    if (userId.isEmpty) {
      return const Stream<Set<String>>.empty();
    }

    return _userSavedCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<List<Recipe>> watchSavedRecipes(String userId) {
    if (userId.isEmpty) {
      return const Stream<List<Recipe>>.empty();
    }

    final savedRef =
        _userSavedCollection(userId).orderBy('savedAt', descending: true);

    return savedRef.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <Recipe>[];
      }

      final ids = snapshot.docs.map((doc) => doc.id).toList();

      final recipeDocs = await _fetchRecipesByIds(ids);
      final recipeMap = {
        for (final doc in recipeDocs) doc.id: Recipe.fromDocument(doc)
      };

      final recipes = <Recipe>[];
      for (final savedDoc in snapshot.docs) {
        final recipe = recipeMap[savedDoc.id];
        if (recipe != null) {
          recipes.add(recipe);
        }
      }
      return recipes;
    });
  }

  Stream<double?> watchUserRating(
      {required String userId, required String recipeId}) {
    if (userId.isEmpty || recipeId.isEmpty) {
      return const Stream<double?>.empty();
    }

    return _userRatingsCollection(userId).doc(recipeId).snapshots().map((doc) {
      final data = doc.data();
      final rating = data?['rating'];
      if (rating is num) {
        return rating.toDouble();
      }
      return null;
    });
  }

  Future<void> toggleSaveRecipe({
    required String userId,
    required String recipeId,
  }) async {
    if (userId.isEmpty || recipeId.isEmpty) {
      return;
    }

    final savedDocRef = _userSavedCollection(userId).doc(recipeId);
    final recipeDocRef = _recipeCollection.doc(recipeId);

    await _firestore.runTransaction((txn) async {
      final savedSnapshot = await txn.get(savedDocRef);
      final recipeSnapshot = await txn.get(recipeDocRef);

      if (!recipeSnapshot.exists) {
        AppLogger.i.w('Recipe $recipeId not found while toggling save.');
        throw StateError('Recipe $recipeId not found');
      }

      final recipeData = recipeSnapshot.data() ?? <String, dynamic>{};
      final currentSavedCount =
          (recipeData['savedCount'] as num?)?.round() ?? 0;

      if (savedSnapshot.exists) {
        txn.delete(savedDocRef);

        final newSavedCount =
            currentSavedCount <= 0 ? 0 : currentSavedCount - 1;
        txn.update(recipeDocRef, {
          'savedCount': newSavedCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(savedDocRef, {
          'recipeId': recipeId,
          'recipeRef': recipeDocRef,
          'savedAt': FieldValue.serverTimestamp(),
        });

        txn.update(recipeDocRef, {
          'savedCount': currentSavedCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> rateRecipe({
    required String userId,
    required String recipeId,
    required double rating,
  }) async {
    if (userId.isEmpty || recipeId.isEmpty) {
      return;
    }

    final normalisedRating = rating.clamp(1.0, 5.0);
    final ratingDocRef = _userRatingsCollection(userId).doc(recipeId);
    final recipeDocRef = _recipeCollection.doc(recipeId);

    await _firestore.runTransaction((txn) async {
      final recipeSnapshot = await txn.get(recipeDocRef);
      if (!recipeSnapshot.exists) {
        AppLogger.i.w('Recipe $recipeId not found while rating.');
        throw StateError('Recipe $recipeId not found');
      }

      final summaryData =
          (recipeSnapshot.data()?['ratingSummary'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
      final currentAverage = summaryData['average'];
      final currentCount = summaryData['count'];

      final existingRatingSnapshot = await txn.get(ratingDocRef);
      final previousRating =
          (existingRatingSnapshot.data()?['rating'] as num?)?.toDouble();

      var ratingCount = currentCount is int ? currentCount : 0;
      var ratingAverage =
          currentAverage is num ? currentAverage.toDouble() : 0.0;

      if (existingRatingSnapshot.exists && previousRating != null) {
        final total = ratingAverage * ratingCount;
        final newTotal = total - previousRating + normalisedRating;
        if (ratingCount <= 0) {
          ratingCount = 1;
        }
        ratingAverage = newTotal / ratingCount;
      } else {
        final total = ratingAverage * ratingCount + normalisedRating;
        ratingCount += 1;
        ratingAverage =
            ratingCount == 0 ? normalisedRating : total / ratingCount;
      }

      txn.set(ratingDocRef, {
        'recipeId': recipeId,
        'recipeRef': recipeDocRef,
        'rating': normalisedRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.update(recipeDocRef, {
        'ratingSummary': {
          'average': double.parse(ratingAverage.toStringAsFixed(2)),
          'count': ratingCount,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> refreshHomeData() async {
    final trendingQuery = _recipeCollection
        .where('isTrending', isEqualTo: true)
        .orderBy('ratingSummary.average', descending: true)
        .limit(10)
        .get(const GetOptions(source: Source.server));

    final recentQuery = _recipeCollection
        .orderBy('createdAt', descending: true)
        .limit(12)
        .get(const GetOptions(source: Source.server));

    final categoriesQuery = _firestore
        .collection('categories')
        .orderBy('order')
        .limit(12)
        .get(const GetOptions(source: Source.server));

    await Future.wait([trendingQuery, recentQuery, categoriesQuery]);
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchRecipesByIds(
    List<String> ids,
  ) async {
    final batches = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      batches.add(
          _recipeCollection.where(FieldPath.documentId, whereIn: chunk).get());
    }

    final results = await Future.wait(batches);
    return results.expand((snapshot) => snapshot.docs).toList();
  }
}
