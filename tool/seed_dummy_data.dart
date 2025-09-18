import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:meal_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = _optionsForCurrentPlatform();
  await Firebase.initializeApp(options: options);

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final categories = _buildCategories();
  for (final category in categories) {
    final doc = firestore.collection('categories').doc(category['id'] as String);
    batch.set(doc, {
      'name': category['name'],
      'slug': category['id'],
      'description': category['description'],
      'accentColor': category['accentColor'],
      'textColor': category['textColor'],
      'heroImageUrl': category['heroImageUrl'],
      'order': category['order'],
      'recipeCount': 0,
    });
  }

  final recipes = _buildRecipes();
  for (final recipe in recipes) {
    final doc = firestore.collection('recipes').doc(recipe['id'] as String);
    batch.set(doc, {
      'name': recipe['name'],
      'description': recipe['description'],
      'author': recipe['author'],
      'ingredients': recipe['ingredients'],
      'steps': recipe['steps'],
      'prepTimeMinutes': recipe['prepTimeMinutes'],
      'cookTimeMinutes': recipe['cookTimeMinutes'],
      'totalTimeMinutes': recipe['totalTimeMinutes'],
      'servings': recipe['servings'],
      'imageUrls': recipe['imageUrls'],
      'thumbnailUrl': recipe['thumbnailUrl'],
      'categories': recipe['categories'],
      'isTrending': recipe['isTrending'],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'ratingSummary': recipe['ratingSummary'],
      'savedCount': recipe['savedCount'],
      'searchKeywords': recipe['searchKeywords'],
    });
  }

  await batch.commit();

  stdout
      .writeln('Seeded ${categories.length} categories and ${recipes.length} recipes.');

  // Exit explicitly so flutter run --target can terminate cleanly.
  exit(0);
}

FirebaseOptions _optionsForCurrentPlatform() {
  if (Platform.isIOS || Platform.isMacOS) {
    return DefaultFirebaseOptions.ios;
  }
  return DefaultFirebaseOptions.android;
}

List<Map<String, Object>> _buildCategories() {
  return [
    {
      'id': 'breakfast',
      'name': 'Breakfast',
      'description': 'Quick energising starts to the day.',
      'accentColor': '0xFFFFE0E0',
      'textColor': '0xFFE23E3E',
      'selectedAccentColor': '0xFFE23E3E',
      'selectedTextColor': '0xFFFFFFFF',
      'heroImageUrl':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200',
      'order': 1,
    },
    {
      'id': 'salad',
      'name': 'Salad',
      'description': 'Crisp greens and feel-good bowls.',
      'accentColor': '0xFFFFE0E0',
      'textColor': '0xFFE23E3E',
      'selectedAccentColor': '0xFFE23E3E',
      'selectedTextColor': '0xFFFFFFFF',
      'heroImageUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200',
      'order': 2,
    },
    {
      'id': 'ramen',
      'name': 'Ramen',
      'description': 'Steaming bowls of comforting noodles.',
      'accentColor': '0xFFFFE0E0',
      'textColor': '0xFFE23E3E',
      'selectedAccentColor': '0xFFE23E3E',
      'selectedTextColor': '0xFFFFFFFF',
      'heroImageUrl':
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=1200',
      'order': 3,
    },
    {
      'id': 'dinner',
      'name': 'Dinner',
      'description': 'Balanced plates ready in 30 minutes or less.',
      'accentColor': '0xFFFFE0E0',
      'textColor': '0xFFE23E3E',
      'selectedAccentColor': '0xFFE23E3E',
      'selectedTextColor': '0xFFFFFFFF',
      'heroImageUrl':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200',
      'order': 4,
    },
  ];
}

List<Map<String, Object>> _buildRecipes() {
  return [
    {
      'id': 'spicy_peanut_ramen',
      'name': 'Spicy Peanut Ramen Bowl',
      'description':
          'Creamy peanut broth ramen with crunchy veg and chili oil drizzle.',
      'author': {
        'id': 'chef_niki',
        'name': 'Niki Samantha',
        'avatarUrl':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
      },
      'ingredients': [
        {
          'name': 'Fresh ramen noodles',
          'quantity': 2,
          'unit': 'bundles',
        },
        {
          'name': 'Peanut butter',
          'quantity': 0.25,
          'unit': 'cup',
        },
        {
          'name': 'Vegetable broth',
          'quantity': 3,
          'unit': 'cups',
        },
        {
          'name': 'Bok choy',
          'quantity': 2,
          'unit': 'heads',
        },
      ],
      'steps': [
        'Whisk broth ingredients until smooth.',
        'Simmer mushrooms and bok choy in peanut broth for 5 minutes.',
        'Cook ramen, assemble bowls, and finish with chili oil.',
      ],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 15,
      'totalTimeMinutes': 25,
      'servings': 2,
      'imageUrls': [
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
      ],
      'thumbnailUrl':
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      'categories': ['ramen', 'dinner'],
      'isTrending': true,
      'ratingSummary': {
        'average': 4.7,
        'count': 18,
      },
      'savedCount': 42,
      'searchKeywords': [
        'spicy',
        'peanut',
        'ramen',
        'chili oil',
        'niki samantha',
      ],
    },
    {
      'id': 'cheddar_shell_salad',
      'name': 'Cheddar Shell Pasta Salad',
      'description':
          'Sweetcorn, cheddar, and shells tossed in creamy yogurt dressing.',
      'author': {
        'id': 'chef_james',
        'name': 'James Oliver',
        'avatarUrl':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      },
      'ingredients': [
        {
          'name': 'Small pasta shells',
          'quantity': 250,
          'unit': 'g',
        },
        {
          'name': 'Sweetcorn',
          'quantity': 1,
          'unit': 'cup',
        },
        {
          'name': 'Cheddar cheese',
          'quantity': 0.75,
          'unit': 'cup',
        },
        {
          'name': 'Greek yogurt',
          'quantity': 0.5,
          'unit': 'cup',
        },
      ],
      'steps': [
        'Cook pasta shells until al dente.',
        'Whisk yogurt dressing with lemon and dill.',
        'Fold pasta, cheddar, sweetcorn, and herbs together.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 10,
      'totalTimeMinutes': 25,
      'servings': 4,
      'imageUrls': [
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      ],
      'thumbnailUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      'categories': ['salad', 'dinner'],
      'isTrending': true,
      'ratingSummary': {
        'average': 4.5,
        'count': 12,
      },
      'savedCount': 31,
      'searchKeywords': [
        'pasta',
        'salad',
        'cheddar',
        'sweetcorn',
        'james oliver',
      ],
    },
    {
      'id': 'indonesian_chicken_burger',
      'name': 'Indonesian Chicken Burger',
      'description':
          'Juicy lemongrass chicken patty with satay glaze and crunchy slaw.',
      'author': {
        'id': 'chef_adrianna',
        'name': 'Adrianna Curl',
        'avatarUrl':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      },
      'ingredients': [
        {
          'name': 'Ground chicken',
          'quantity': 500,
          'unit': 'g',
        },
        {
          'name': 'Lemongrass',
          'quantity': 2,
          'unit': 'stalks',
        },
        {
          'name': 'Peanut sauce',
          'quantity': 0.5,
          'unit': 'cup',
        },
        {
          'name': 'Brioche buns',
          'quantity': 4,
          'unit': 'pieces',
        },
      ],
      'steps': [
        'Combine chicken with lemongrass, garlic, and spices.',
        'Shape into patties and sear until caramelised.',
        'Glaze with peanut sauce and build burgers with slaw.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'totalTimeMinutes': 35,
      'servings': 4,
      'imageUrls': [
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
      ],
      'thumbnailUrl':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      'categories': ['dinner'],
      'isTrending': false,
      'ratingSummary': {
        'average': 4.2,
        'count': 6,
      },
      'savedCount': 14,
      'searchKeywords': [
        'burger',
        'chicken',
        'satay',
        'indonesian',
      ],
    },
    {
      'id': 'overnight_oats',
      'name': 'Blueberry Almond Overnight Oats',
      'description':
          'Creamy vanilla oats soaked overnight with berries and almond crunch.',
      'author': {
        'id': 'chef_roberta',
        'name': 'Roberta Amy',
        'avatarUrl':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      },
      'ingredients': [
        {
          'name': 'Rolled oats',
          'quantity': 1,
          'unit': 'cup',
        },
        {
          'name': 'Greek yogurt',
          'quantity': 0.5,
          'unit': 'cup',
        },
        {
          'name': 'Almond milk',
          'quantity': 1,
          'unit': 'cup',
        },
        {
          'name': 'Blueberries',
          'quantity': 0.75,
          'unit': 'cup',
        },
      ],
      'steps': [
        'Stir oats with yogurt, milk, vanilla, and chia seeds.',
        'Fold in blueberries and spoon into jars.',
        'Chill overnight and top with toasted almonds.',
      ],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 0,
      'totalTimeMinutes': 10,
      'servings': 2,
      'imageUrls': [
        'https://images.unsplash.com/photo-1528712306091-ed0763094c98?w=800',
      ],
      'thumbnailUrl':
          'https://images.unsplash.com/photo-1528712306091-ed0763094c98?w=400',
      'categories': ['breakfast'],
      'isTrending': false,
      'ratingSummary': {
        'average': 4.8,
        'count': 24,
      },
      'savedCount': 57,
      'searchKeywords': [
        'oats',
        'overnight',
        'blueberry',
        'breakfast',
      ],
    },
  ];
}
