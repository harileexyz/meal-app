import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../theme/app_theme.dart';
import 'auth_store.dart';

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  late final AuthStore _store;

  @override
  void initState() {
    super.initState();
    _store = AuthStore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppTheme.screenPadding.left,
            right: AppTheme.screenPadding.right,
            bottom: bottomInset + AppTheme.screenPadding.bottom,
            top: AppTheme.screenPadding.top,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Welcome back',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in with Google to start planning your meals and sync across devices.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Observer(
                  builder: (_) {
                    return FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.buttonRed,
                        foregroundColor: AppTheme.background,
                      ),
                      onPressed: _store.isLoading
                          ? null
                          : () async {
                              final signedIn = await _store.signInWithGoogle();
                              if (!mounted) {
                                return;
                              }
                              if (signedIn) {
                                widget.onSignedIn();
                              }
                            },
                      icon: _store.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _store.isLoading ? 'Signing in...' : 'Sign in with Google',
                      ),
                    );
                  },
                ),
                Observer(
                  builder: (_) {
                    final message = _store.errorMessage;
                    if (message == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
