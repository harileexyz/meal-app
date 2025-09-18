# App architecture overview

The app follows a lightweight MVVM-inspired layering:

- **View (Widgets)** – Build UI, respond to user gestures, and render data exposed by stores. Widgets stay free of business logic and never talk to Firebase directly.
- **ViewModel (MobX stores)** – Orchestrate UI state, subscribe to repository streams, expose observables, and provide actions for the UI (`HomeStore` lives here).
- **Repository layer** – Wraps Firestore/Auth APIs and returns domain models (`RecipeRepository`). Repositories are free of Flutter dependencies, which keeps them testable.
- **Models** – Plain Dart objects describing data flowing through the app (`Recipe`, `Category`, `RatingSummary`, etc.).
- **Utilities** – Cross-cutting helpers such as logging (`AppLogger`).

## Data flow

```
Widget ──(calls actions)──▶ MobX Store ──(delegates)──▶ Repository ──▶ Firestore
  ▲                                 │
  └────── Observer rebuilds ◀───────┘  (store publishes new observable values)
```

- Stores listen to Firestore via repositories and push updates into `ObservableList`/`ObservableSet` instances.
- Widgets use `Observer` to reactively rebuild when the store changes.
- User actions (save, rate, refresh) call store methods, which in turn execute repository operations and update state.

## Extending the pattern

1. Add a store per feature (e.g. `SavedStore`, `AuthStore`).
2. Inject repositories into stores (using `Provider`, `get_it`, or similar).
3. Keep widgets dumb – they read store state and invoke store actions.
4. Add unit tests by mocking repositories and asserting store behaviour.

This separation keeps UI responsive, surfaces errors in one place, and makes it straightforward to scale the code base as more features arrive.
