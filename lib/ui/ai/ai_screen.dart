import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Center(
          child: Text(
            'AI meal planning features coming soon.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
