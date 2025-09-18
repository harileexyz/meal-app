import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/popular_categories.dart';
import '../components/popular_creators.dart';
import '../components/recent_recipes.dart';
import '../components/search_header.dart';
import '../components/trending_recipes.dart';
import '../../stores/home_store.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeStore = context.read<HomeStore>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: homeStore.refresh,
        edgeOffset: 16,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: const [
            SizedBox(height: 16),
            SearchHeader(),
            SizedBox(height: 24),
            TrendingRecipes(),
            SizedBox(height: 24),
            PopularCategories(),
            SizedBox(height: 24),
            RecentRecipes(),
            SizedBox(height: 24),
            PopularCreators(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
