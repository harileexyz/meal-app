# Logging guidelines

The app now uses the [`logger`](https://pub.dev/packages/logger) package behind a small wrapper (`AppLogger` in `lib/utils/app_logger.dart`). Always log through `AppLogger.i` instead of `print` calls so we can tune formatting and levels globally.

## Usage

```dart
import 'utils/app_logger.dart';

AppLogger.i.d('Subscribed to trending recipes');
AppLogger.i.w('Recipe $recipeId missing while saving');
AppLogger.i.e('Failed to fetch data', error: error, stackTrace: stackTrace);
```

- `d` – verbose/debug information
- `w` – warnings (unexpected but recoverable)
- `e` – errors/exceptions

## Setup highlights

- Dependency: `logger: ^2.2.0` (see `pubspec.yaml`). Run `flutter pub get` after pulling.
- Wrapper: `lib/utils/app_logger.dart` exposes a single shared instance configured with `PrettyPrinter`.
- Usage example in production code: `watchTrendingRecipes` now logs stream subscriptions, and transactions warn when documents are missing (`lib/repositories/recipe_repository.dart:18`).

## Tips

1. Prefer contextual messages (include IDs, parameters).
2. Log once per operation (subscribe, success/failure) instead of each emitted item.
3. Avoid reintroducing `print`; it bypasses our formatter and can’t be silenced per build.
4. For very noisy logs, guard with `if (AppLogger.i.level <= Level.debug)` before emitting.

Following these guidelines keeps logs consistent and easy to filter in production.
