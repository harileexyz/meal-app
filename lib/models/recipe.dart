import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeAuthor {
  const RecipeAuthor({
    required this.name,
    this.id,
    this.avatarUrl,
  });

  final String? id;
  final String name;
  final String? avatarUrl;

  factory RecipeAuthor.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const RecipeAuthor(name: 'Unknown chef');
    }

    final avatarUrl = data['avatarUrl'] as String?;
    return RecipeAuthor(
      id: data['id'] as String?,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Unknown chef',
      avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl : null,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    this.quantity,
    this.unit,
  });

  final String name;
  final num? quantity;
  final String? unit;

  factory RecipeIngredient.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const RecipeIngredient(name: 'Unknown ingredient');
    }

    return RecipeIngredient(
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Unknown ingredient',
      quantity: data['quantity'] is num ? data['quantity'] as num : null,
      unit: (data['unit'] as String?)?.trim().isNotEmpty == true
          ? (data['unit'] as String).trim()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
      };
}

class RatingSummary {
  const RatingSummary({
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

  factory RatingSummary.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const RatingSummary(average: 0, count: 0);
    }

    final average = data['average'];
    final count = data['count'];

    return RatingSummary(
      average: average is int
          ? average.toDouble()
          : average is double
              ? average
              : 0,
      count: count is int ? count : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'average': average,
        'count': count,
      };
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.ingredients,
    required this.steps,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.totalTimeMinutes,
    required this.servings,
    required this.imageUrls,
    required this.thumbnailUrl,
    required this.categories,
    required this.isTrending,
    required this.createdAt,
    required this.updatedAt,
    required this.ratingSummary,
    required this.savedCount,
  });

  final String id;
  final String name;
  final String description;
  final RecipeAuthor author;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int totalTimeMinutes;
  final int servings;
  final List<String> imageUrls;
  final String thumbnailUrl;
  final List<String> categories;
  final bool isTrending;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RatingSummary ratingSummary;
  final int savedCount;

  String get primaryImage => thumbnailUrl.isNotEmpty
      ? thumbnailUrl
      : imageUrls.isNotEmpty
          ? imageUrls.first
          : '';

  String get authorDisplay => author.name;

  String get timeLabel =>
      totalTimeMinutes > 0 ? '${totalTimeMinutes.round()} Min' : '—';

  factory Recipe.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    List<String> stringList(dynamic value) {
      if (value is Iterable) {
        return value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return const [];
    }

    List<RecipeIngredient> ingredients(dynamic value) {
      if (value is Iterable) {
        return value
            .whereType<Map<String, dynamic>>()
            .map(RecipeIngredient.fromMap)
            .toList(growable: false);
      }
      return const [];
    }

    DateTime? timestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    return Recipe(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Untitled recipe',
      description: (data['description'] as String?)?.trim() ?? '',
      author: RecipeAuthor.fromMap(data['author'] as Map<String, dynamic>?),
      ingredients: ingredients(data['ingredients']),
      steps: stringList(data['steps']),
      prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.round() ?? 0,
      cookTimeMinutes: (data['cookTimeMinutes'] as num?)?.round() ?? 0,
      totalTimeMinutes: (data['totalTimeMinutes'] as num?)?.round() ??
          ((data['prepTimeMinutes'] as num?)?.round() ?? 0) +
              ((data['cookTimeMinutes'] as num?)?.round() ?? 0),
      servings: (data['servings'] as num?)?.round() ?? 0,
      imageUrls: stringList(data['imageUrls']),
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.trim() ?? '',
      categories: stringList(data['categories']),
      isTrending: data['isTrending'] == true,
      createdAt: timestamp(data['createdAt']),
      updatedAt: timestamp(data['updatedAt']),
      ratingSummary:
          RatingSummary.fromMap(data['ratingSummary'] as Map<String, dynamic>?),
      savedCount: (data['savedCount'] as num?)?.round() ?? 0,
    );
  }
}
