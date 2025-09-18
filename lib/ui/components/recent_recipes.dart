import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../stores/home_store.dart';

class RecentRecipes extends StatelessWidget {
  const RecentRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    final homeStore = context.read<HomeStore>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent recipe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
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
          height: 140,
          child: Observer(
            builder: (_) {
              final recipes = homeStore.recentRecipes.toList(growable: false);
              final isLoaded = homeStore.recentLoaded.value;
              final error = homeStore.errorMessage.value;

              if (!isLoaded && recipes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (error != null && recipes.isEmpty) {
                return Center(
                  child: Text(
                    'Could not load recent recipes',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (recipes.isEmpty) {
                return const Center(
                  child: Text('No recipes yet. Add some in Firestore.'),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final image = recipe.primaryImage;

                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 80,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.restaurant_menu, size: 24),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'By ${recipe.authorDisplay}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
}
