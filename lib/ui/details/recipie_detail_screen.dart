import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/recipe.dart';
import '../../theme/app_theme.dart';

class RecipieDetailScreen extends StatefulWidget {
  const RecipieDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipieDetailScreen> createState() => _RecipieDetailScreenState();
}

class _RecipieDetailScreenState extends State<RecipieDetailScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  bool _showDarkBackIcon = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 0.0,
    );

    // Start the animation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    const collapseThreshold = 160.0;
    final shouldShowDark = _scrollController.hasClients &&
        _scrollController.offset > collapseThreshold;

    if (_showDarkBackIcon != shouldShowDark) {
      setState(() {
        _showDarkBackIcon = shouldShowDark;
      });
      if (shouldShowDark) {
        _fadeController.forward();
        HapticFeedback.lightImpact();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            pinned: true,
            expandedHeight: 320,
            iconTheme: IconThemeData(
              color: _showDarkBackIcon ? Colors.black : Colors.white,
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showDarkBackIcon
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showDarkBackIcon
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    size: 22,
                    color: _showDarkBackIcon ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Add favorite functionality
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showDarkBackIcon
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.share,
                    size: 22,
                    color: _showDarkBackIcon ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Add share functionality
                  },
                ),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.biggest.height <= 120;
                final opacity = isCollapsed ? 1.0 : 0.0;

                return FlexibleSpaceBar(
                  titlePadding: isCollapsed
                      ? const EdgeInsetsDirectional.only(
                          start: 50, end: 16, bottom: 16)
                      : EdgeInsets.zero,
                  title: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      recipe.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: recipe.primaryImage.isNotEmpty
                            ? Hero(
                                tag: 'recipe-${recipe.name}',
                                child: Image.network(
                                  recipe.primaryImage,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.3),
                                      Colors.red.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _InfoBadge(
                                  icon: Icons.star,
                                  label: recipe.ratingSummary.average
                                      .toStringAsFixed(1),
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                _InfoBadge(
                                  icon: Icons.schedule,
                                  label: recipe.timeLabel,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleController.value,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AuthorRow(recipe: recipe),
                        const SizedBox(height: 28),
                        _OverviewGrid(recipe: recipe),
                        if (recipe.description.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const _SectionTitle('Why you will love it'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.05),
                                  Colors.red.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              recipe.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[700],
                                height: 1.6,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),
                        const _SectionTitle('Ingredients'),
                        const SizedBox(height: 16),
                        _IngredientList(recipe: recipe),
                        const SizedBox(height: 36),
                        const _SectionTitle('Method'),
                        const SizedBox(height: 16),
                        _StepList(recipe: recipe),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[100],
              backgroundImage: recipe.author.avatarUrl != null
                  ? NetworkImage(recipe.author.avatarUrl!)
                  : null,
              child: recipe.author.avatarUrl == null
                  ? Text(
                      recipe.author.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.authorDisplay,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Shared this recipe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.withOpacity(0.1),
                  Colors.red.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.deepOrange),
                const SizedBox(width: 6),
                Text(
                  recipe.timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _OverviewTile(
          title: 'Prep time',
          value: _formatMinutes(recipe.prepTimeMinutes),
          icon: Icons.timer_outlined,
          color: Colors.blue,
        ),
        _OverviewTile(
          title: 'Cook time',
          value: _formatMinutes(recipe.cookTimeMinutes),
          icon: Icons.restaurant,
          color: Colors.green,
        ),
        _OverviewTile(
          title: 'Total time',
          value: _formatMinutes(recipe.totalTimeMinutes),
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _OverviewTile(
          title: 'Servings',
          value: recipe.servings > 0 ? '${recipe.servings}' : '—',
          icon: Icons.person_outline,
          color: Colors.purple,
        ),
        _OverviewTile(
          title: 'Saved',
          value: '${recipe.savedCount}',
          icon: Icons.favorite_outline,
          color: Colors.red,
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '—';
    return '$minutes min';
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _IngredientList extends StatelessWidget {
  const _IngredientList({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    if (recipe.ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Text(
          'Ingredients are coming soon.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < recipe.ingredients.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    recipe.ingredients[i].name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.4,
                        ),
                  ),
                ),
                if (recipe.ingredients[i].quantity != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatQuantity(
                        recipe.ingredients[i].quantity!,
                        recipe.ingredients[i].unit,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatQuantity(num quantity, String? unit) {
    String value;
    if (quantity % 1 == 0) {
      value = quantity.toInt().toString();
    } else {
      value = quantity
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      if (value.isEmpty) {
        value = quantity.toString();
      }
    }

    if (unit != null && unit.isNotEmpty) {
      return '$value $unit';
    }
    return value;
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    if (recipe.steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Text(
          'Cooking steps will be available soon.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < recipe.steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepNumber(index: i + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    recipe.steps[i],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontSize: 15,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$index',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
          ),
    );
  }
}
