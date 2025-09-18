import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../stores/home_store.dart';

class PopularCategories extends StatelessWidget {
  const PopularCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final homeStore = context.read<HomeStore>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Observer(
          builder: (_) {
            final categories = homeStore.categories.toList(growable: false);
            final trendingRecipes =
                homeStore.trendingRecipes.toList(growable: false);
            final selectedSlug = homeStore.selectedCategorySlug.value;
            final categoriesLoaded = homeStore.categoriesLoaded.value;
            final trendingLoaded = homeStore.trendingLoaded.value;
            final error = homeStore.errorMessage.value;

            if (!categoriesLoaded && categories.isEmpty) {
              return const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (error != null && categories.isEmpty) {
              return Text(
                'Could not load categories',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              );
            }

            if (categories.isEmpty) {
              return const Text('Add categories in Firestore to see them here.');
            }

            final effectiveSlug =
                (selectedSlug?.isNotEmpty == true ? selectedSlug : null) ??
                    categories.first.slug;
            final filteredRecipes = trendingRecipes
                .where((recipe) => recipe.categories.contains(effectiveSlug))
                .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.slug == effectiveSlug;

                      final selectedBackground = _parseColor(
                        category.selectedAccentColor ?? category.accentColor,
                        const Color(0xFFFFE0E0),
                      );
                      final unselectedBackground = Color.lerp(
                        selectedBackground,
                        Colors.white,
                        0.45,
                      )!;
                      final selectedText = _parseColor(
                        category.selectedTextColor ?? category.textColor,
                        const Color(0xFFE23E3E),
                      );
                      final unselectedText = selectedText.withOpacity(0.7);
                      final backgroundColor =
                          isSelected ? selectedBackground : unselectedBackground;
                      final textColor =
                          isSelected ? selectedText : unselectedText;

                      return GestureDetector(
                        onTap: () =>
                            homeStore.setSelectedCategory(category.slug),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? selectedText.withOpacity(0.8)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (!trendingLoaded && filteredRecipes.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredRecipes.isEmpty)
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text('No trending recipes in this category yet.'),
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        final image = recipe.primaryImage;

                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: image.isNotEmpty
                                      ? Image.network(
                                          image,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.restaurant_menu,
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.timeLabel,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _parseColor(String value, Color fallback) {
    if (value.isEmpty) {
      return fallback;
    }

    final normalised = value.startsWith('0x') ? value : '0x$value';
    final parsed = int.tryParse(normalised);
    if (parsed == null) {
      return fallback;
    }
    return Color(parsed);
  }
}
