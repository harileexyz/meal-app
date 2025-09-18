import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../stores/home_store.dart';

class PopularCreators extends StatelessWidget {
  const PopularCreators({super.key});

  @override
  Widget build(BuildContext context) {
    final homeStore = context.read<HomeStore>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular creators',
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
        Observer(
          builder: (_) {
            final recipes = homeStore.trendingRecipes.toList(growable: false);
            final isLoaded = homeStore.trendingLoaded.value;
            final error = homeStore.errorMessage.value;

            if (!isLoaded && recipes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && recipes.isEmpty) {
              return Text(
                'Could not load creators',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              );
            }

            if (recipes.isEmpty) {
              return const Text('Add recipes to highlight creators.');
            }

            final seen = <String>{};
            final creators = <RecipeAuthor>[];
            for (final recipe in recipes) {
              final author = recipe.author;
              final key = author.id?.isNotEmpty == true
                  ? author.id!
                  : author.name.toLowerCase();
              if (seen.contains(key)) {
                continue;
              }
              seen.add(key);
              creators.add(author);
              if (creators.length >= 4) {
                break;
              }
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: creators.map((creator) {
                final avatar = creator.avatarUrl;
                final initials = creator.name.isNotEmpty
                    ? creator.name.substring(0, 1).toUpperCase()
                    : '?';
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar == null || avatar.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        creator.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
