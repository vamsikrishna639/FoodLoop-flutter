# FoodLoop: Flutter app

The Flutter frontend (web and Android) for FoodLoop. Setup, test logins and the
demo script are in the [root README](../README.md); the design system is in
[DESIGN.md](../DESIGN.md).

```bash
flutter pub get
flutter run -d chrome          # needs the backend on http://localhost:5000
flutter analyze
```

Layout of `lib/`:

| Folder | What is in it |
|---|---|
| `core/` | Theme tokens (`theme/`), router, API client, config, responsive helpers |
| `models/` | Plain data classes parsed from the API |
| `services/` | One class per API area (auth, food, claims, pickups, ...) |
| `providers/` | App state (`provider` package) |
| `screens/` | `auth`, `recipient`, `donor`, `volunteer`, `admin`, `common` |
| `widgets/` | Signature components: TokenCard, StatusStamp, ReceiptTimeline, Chalkboard, ... |
