# Meal Prep Planner

A learning-focused Flutter app that evolves into a production-quality meal planning experience. The project serves two purposes:

1. Build a Firebase-backed recipe browser/saver for personal meal prep.
2. Practice modern Flutter architecture patterns (MVVM, state management with MobX, repository pattern, logging, etc.).

This README is a running document that records the decisions, tools, and practices used along the way.

---

## Quick start

1. **Clone & install deps**
   ```bash
   flutter pub get
   ```
   (Run locally; the sandbox cannot reach pub.dev.)

2. **Configure Firebase**
   - Create a Firebase project (e.g. `meal-prep-8cc05`).
   - Enable Authentication (Email/Password or Google Sign-In) and Firestore.
   - Download platform config files (`google-services.json`, `GoogleService-Info.plist`).
   - Regenerate `lib/firebase_options.dart` with the FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

3. **Seed Firestore (optional)**
   ```bash
   flutter run -d <device-id> --no-pub --target tool/seed_dummy_data.dart
   ```
   This writes sample categories and recipes used by the home feed.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## Architecture & state management

### High-level pattern

The app follows an MVVM-inspired structure:

```
Widget (View) ──calls──▶ MobX Store (ViewModel) ──delegates──▶ Repository ──▶ Firestore/Auth
   ▲                               │
   └───────── Observer rebuilds ◀──┘
```

- **Views (Widgets)** – build the UI, dispatch user events, and observe store state via `Observer` widgets.
- **Stores (MobX)** – encapsulate UI logic, manage subscriptions to repositories, expose observable state, and surface actions (`HomeStore` currently drives the home tab).
- **Repositories** – coordinate with Firebase while returning domain models (e.g. `RecipeRepository` for Firestore access).
- **Models** – plain Dart objects (`Recipe`, `Category`, `RatingSummary`, etc.) typed for secure parsing/serialization.
- **Utilities** – cross-cutting concerns such as logging (`AppLogger`).

### Dependency injection

For now, dependency wiring is handled with `provider`:

- `HomePage` creates a single `HomeStore` and exposes it via `Provider` to child widgets.
- Widgets retrieve the store with `context.read<HomeStore>()` and listen using `Observer`.
- As the project grows we can move to `get_it` or Riverpod, but provider keeps things lightweight for learning.

### Stores

- `lib/stores/home_store.dart` owns all home-tab state.
  - Observables: trending recipes, recent recipes, categories, saved recipe IDs, loading/error flags.
  - Actions: `refresh`, `toggleSave`, `rateRecipe`, `getUserRating`.
  - Subscribes to Firestore streams via `RecipeRepository` and updates observables.
  - Manages per-user state (saved IDs/ratings) based on FirebaseAuth user ID.

Future work: create `AuthStore`, `SavedStore`, etc. using the same pattern.

---

## Data & Firestore practices

- **Collections & schema** documented in [`docs/firestore_schema.md`](docs/firestore_schema.md).
- Composite indexes are defined in `firestore.indexes.json` and deployed via `firebase deploy --only firestore:indexes`.
- Repositories use typed models to avoid runtime map lookups.
- Reads are mostly streaming (`snapshots()`) for live UI updates. `refreshHomeData()` forces fresh server reads (pull-to-refresh).
- User-specific data (saves/ratings) live under `users/{uid}/...` sub-collections for easy security rule enforcement.

## Networking/API calls

All Firebase calls flow through `RecipeRepository`:

- `watchTrendingRecipes`, `watchRecentRecipes`, `watchCategories` return streams of models.
- `toggleSaveRecipe` and `rateRecipe` wrap Firestore transactions to keep counters accurate.
- `refreshHomeData` hits Firestore with `GetOptions(source: Source.server)` to bypass cache during pull-to-refresh.

Stores subscribe to these streams and translate results into `ObservableList` / `ObservableSet` for the UI.

---

## UI guidelines & components

- Home tab is composed of modular widgets (`TrendingRecipes`, `PopularCategories`, `RecentRecipes`, `PopularCreators`) that simply watch store data.
- Lists use fixed heights plus `Flexible`/`Expanded` to avoid `RenderFlex overflow` issues on narrow devices.
- Pull-to-refresh uses `RefreshIndicator` tied to `HomeStore.refresh`.
- Snackbar messaging centralised in widgets for quick feedback.
- Reusable components (e.g., `_RecipeCard`) favour defensive fallbacks (placeholder image, initials when avatar missing).

---

## Logging & diagnostics

- `AppLogger` wraps the [`logger`](https://pub.dev/packages/logger) package.
- Use `AppLogger.i.d/w/e` instead of `print` for structured output.
- Stores log errors via `_handleError`, which also exposes messages to the UI.

---

## Project layout

```
lib/
├── app.dart                    # Root MaterialApp
├── main.dart                   # App entry, logger init, Firebase init
├── components/                 # UI building blocks for the home feed
├── repositories/               # Firestore repository layer
├── stores/                     # MobX stores (currently HomeStore)
├── models/                     # Typed data models
├── utils/                      # Helpers (AppLogger)
├── home/                       # Home page + view wiring
├── auth/, ai/, profile/, saved/ # Feature modules (work in progress)
└── theme/                      # App-wide theming
```

Documentation lives under `docs/` (`architecture.md`, `firestore_schema.md`, etc.).

---

## Tooling & scripts

- `tool/seed_dummy_data.dart` seeds Firestore with starter recipes/categories (run using `flutter run --target ...`).
- `firebase deploy --only firestore:indexes` to publish index changes.
- `flutter pub run build_runner build` (future) if/when MobX stores use code generation.

---

## Learning notes (keep adding!)

- Flutter UI is declarative; use immutable widgets and let state (stores) drive rebuilds.
- MobX observables simplify reactive updates; remember to wrap mutations in `runInAction` when changing state asynchronously.
- Firestore `snapshots()` deliver cached data first; call `refreshHomeData()` for server freshness.
- Composite indexes require exact order/direction matching the query (`ratingSummary.average DESC`, `__name__ DESC`).
- Debugging layout: watch for `RenderFlex overflow` warnings; ensure widgets have constrained heights/widths (`SizedBox`, `Flexible`).
- Logging visually—`logger` prints with timestamps/emojis to quickly trace state transitions.

Add more lessons learned, TODOs, and architectural decisions here as the project evolves.

---

## Roadmap / TODO

- [ ] Create `AuthStore` to wrap FirebaseAuth streams and expose user/session state.
- [ ] Convert Saved tab to use a dedicated MobX store instead of direct repository access.
- [ ] Implement recipe detail screens with hero animations.
- [ ] Add Firestore security rules and tests.
- [ ] Evaluate introduction of `get_it` or Riverpod for dependency management at scale.
- [ ] Add integration tests using the Firestore emulator.

PRs and experiments welcome—this project is meant to grow along with new Flutter knowledge.
