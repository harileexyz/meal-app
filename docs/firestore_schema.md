# Firestore data model

The app uses Firestore to drive the recipe feed, categories, and user-specific interactions (saved recipes and star ratings). The following schema keeps reads fast from mobile, keeps writes simple, and makes aggregations easy to cache.

## Collections overview

### `recipes`
Stores every recipe that can appear in the app.

| Field | Type | Purpose |
| --- | --- | --- |
| `name` | string | Recipe title shown in lists and detail views |
| `description` | string | Short intro / teaser |
| `author` | map | `{ id, name, avatarUrl }` for attribution |
| `ingredients` | array<map> | Each map: `{ name, quantity, unit }` (unit optional) |
| `steps` | array<string> | Ordered cooking instructions |
| `prepTimeMinutes` | number | Prep time |
| `cookTimeMinutes` | number | Cook time |
| `totalTimeMinutes` | number | Derived total time (used for quick display) |
| `servings` | number | Number of servings |
| `imageUrls` | array<string> | Recipe/gallery images |
| `thumbnailUrl` | string | Primary image for list cards |
| `categories` | array<string> | Category document IDs for quick filtering |
| `isTrending` | bool | Flag to highlight on home screen |
| `createdAt` | timestamp | Creation time (used for "recent" section) |
| `updatedAt` | timestamp | Latest update |
| `ratingSummary` | map | `{ average: double, count: number }` cached aggregate |
| `savedCount` | number | Cached total saves |
| `searchKeywords` | array<string> | Lowercased keywords for client-side search (optional) |

**Example document**
```json
{
  "name": "Spicy Peanut Ramen Bowl",
  "description": "Creamy peanut broth ramen with crunchy veggies.",
  "author": {
    "id": "chef_niki",
    "name": "Niki Samantha",
    "avatarUrl": "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100"
  },
  "ingredients": [
    { "name": "Fresh ramen noodles", "quantity": 2, "unit": "bundles" },
    { "name": "Peanut butter", "quantity": 0.25, "unit": "cup" }
  ],
  "steps": [
    "Whisk broth ingredients until smooth.",
    "Simmer mushrooms and bok choy for 5 minutes.",
    "Cook ramen, assemble bowls, and top with chili oil."
  ],
  "prepTimeMinutes": 10,
  "cookTimeMinutes": 15,
  "totalTimeMinutes": 25,
  "servings": 2,
  "imageUrls": [
    "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800"
  ],
  "thumbnailUrl": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400",
  "categories": ["ramen", "dinner"],
  "isTrending": true,
  "createdAt": {"_seconds": 1714600000, "_nanoseconds": 0},
  "updatedAt": {"_seconds": 1714600000, "_nanoseconds": 0},
  "ratingSummary": {"average": 4.6, "count": 18},
  "savedCount": 42,
  "searchKeywords": ["spicy", "peanut", "ramen", "nikisamantha"]
}
```

### `categories`
Human-friendly buckets used across the app. Recipes reference categories by ID.

| Field | Type | Purpose |
| --- | --- | --- |
| `name` | string | Display name |
| `slug` | string | Lowercase identifier (used in `recipes.categories`) |
| `description` | string | Optional longer copy |
| `heroImageUrl` | string | Image banner for category detail |
| `accentColor` | string | Hex or ARGB string used for chips |
| `textColor` | string | Hex/ARGB string for contrast |
| `order` | number | Optional ordering weight |
| `recipeCount` | number | Cached number of recipes in this category |

**Example document**
```json
{
  "name": "Breakfast",
  "slug": "breakfast",
  "description": "Quick energising starts to the day.",
  "accentColor": "0xFFE23E3E",
  "textColor": "0xFFFFFFFF",
  "heroImageUrl": "https://images.unsplash.com/photo-1528712306091-ed0763094c98?w=1200",
  "order": 10,
  "recipeCount": 8
}
```

### `users`
Basic profile cache for app-specific data.

| Field | Type | Purpose |
| --- | --- | --- |
| `displayName` | string | Mirrors Firebase Auth display name |
| `photoUrl` | string | Avatar |
| `createdAt` | timestamp | First login |
| `lastSeenAt` | timestamp | Updated whenever the user opens the app |

Sub-collections under each user control personalised data:

- `users/{userId}/savedRecipes/{recipeId}`
  - Fields: `recipeId`, `recipeRef` (DocumentReference), `savedAt`
- `users/{userId}/ratings/{recipeId}`
  - Fields: `recipeId`, `recipeRef`, `rating` (1–5), `updatedAt`

### `recipeInteractions`
(OPTIONAL) Shared collection for analytics. If you need global ratings or saves without scanning all users, mirror writes here using Cloud Functions or client transactions.

| Field | Type | Purpose |
| --- | --- | --- |
| `type` | string | `'save' | 'rating'` |
| `recipeId` | string | Target recipe |
| `userId` | string | Actor |
| `rating` | number | Present only for `type == 'rating'` |
| `createdAt` | timestamp | Event time |

## Query patterns & indexes

1. **Trending section** – query `recipes` where `isTrending == true` order by `ratingSummary.average` desc.
2. **Recent recipes** – query `recipes` order by `createdAt` desc limit 10.
3. **Category filter** – query `recipes` where `categories` array contains `<slug>` order by `ratingSummary.average` desc.
4. **Saved list** – listen to `users/{uid}/savedRecipes` to get IDs, then fetch recipe docs using `whereIn` batches.
5. **User rating** – read `users/{uid}/ratings/{recipeId}` and merge with `recipes.ratingSummary` for display.

Add composite indexes for:
- `recipes` on `isTrending` (asc) + `ratingSummary.average` (desc)
- `recipes` on `categories` (array contains) + `ratingSummary.average` (desc)

## Aggregation strategy

- When a user rates a recipe, write to their personal rating document and update `recipes.ratingSummary` in a transaction: fetch current summary, compute new average/count, write back.
- When a user saves/unsaves, add or remove `users/{uid}/savedRecipes/{recipeId}` and increment/decrement `recipes.savedCount` in a transaction if that metric is needed.

This structure keeps user-specific data isolated (fast security rules) and lets the feed queries stay simple and inexpensive.
