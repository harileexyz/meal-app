import 'package:flutter/material.dart';

import '../../auth/auth_bottom_sheet.dart';
import '../../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _showAuthSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return AuthBottomSheet(
          onSignedIn: () {
            Navigator.of(sheetContext).pop(true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.8, // 0.0 = fully transparent, 1.0 = fully opaque
            child: Image.asset(
              'assets/images/landing_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Spacer(),
                  const Spacer(),
                  Text(
                    'Lets Get Cooking',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      color: AppTheme.background,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find best recipes and get cooking.',
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.parent,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _showAuthSheet(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.buttonRed,
                      foregroundColor: AppTheme.background,
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
