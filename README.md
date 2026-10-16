# Vista Care

A Flutter owner dashboard for a six-branch clinic network: Laguna, Pasig,
Caloocan, Parañaque, Quezon City, and Valenzuela.

## Run

```sh
flutter pub get
flutter run
```

Use `flutter run -d chrome` for a browser preview.

## iPhone screen preview

Debug builds start with Device Preview's iPhone 16 preset, including its
screen size, safe areas, and device frame. Run `flutter run -d chrome` to
view it in a browser, or run on the Android emulator as usual.

Open Flutter DevTools from VS Code with **Dart: Open DevTools**, then select
the **device_preview** extension to change devices, rotate the screen, or
adjust text size and appearance. Device Preview 3 uses DevTools rather than
an in-app device selector.

To use the actual emulator or browser dimensions instead:

```sh
flutter run --dart-define=DEVICE_PREVIEW=false
```

Preview is disabled in release builds and in ordinary profile builds. This simulates iPhone
layout and Flutter platform behavior; it does not run iOS or test native iOS
plugins. See the [Device Preview documentation](https://pub.dev/packages/device_preview).

## Included

- Five phone tabs: Home, Daily reports, Statistics, Revenue, and Branches.
- Responsive desktop navigation and branch filtering across the dashboard.
- Branch profiles with patient trends, daily revenue targets, inventory, and staff ratings.
- Medicine batch entry with quantity, units, branch, expiry date, and low-stock threshold.
- Restocking and quantity corrections, low-stock alerts, and expiry alerts within 60 days.
- Daily report entry and editing, date selection, patient counts, collections, expenses, and notes.
- Seven-day and thirty-day patient and revenue summaries, plus net revenue and margin.

## Demo data and storage

This is an interactive UI prototype. All clinic totals, staff reviews, branch
addresses, and medicine batches are illustrative sample data. Thirty days of
reports are generated on launch. Dates use Philippine time (UTC+8).

Changes are stored in memory and reset on app restart. Saving a daily report
replaces the existing report for the same branch and date. Restocking adds to
the selected batch; deliveries with a different expiry should be added as a
new batch. Inventory alerts are displayed inside the app.

Production use still requires authentication, a persistent database, shared
branch synchronization, access controls, audit records, and notification delivery.

## Structure

- `lib/main.dart`: app entry and theme.
- `lib/pages/`: navigation shell and individual screens.
- `lib/data/clinic_store.dart`: shared state, sample data, and aggregation.
- `lib/widgets/clinic_ui.dart`: reusable cards, charts, selectors, and design colors.

## Verify

```sh
flutter analyze
flutter test
flutter build web --release
```

## GitHub Pages demo

The iPhone layout preview is published at:

https://elijahdelmundo.github.io/veritas_prototype-0.1/

The workflow in `.github/workflows/pages.yml` analyzes, tests, builds, and deploys
on pushes to `main`. In repository **Settings > Pages**, use **GitHub Actions**
as the source. Deployments appear under **Actions > Deploy Flutter preview to
GitHub Pages** and can also be started with **Run workflow**.

The hosted demo deliberately uses a profile web build with
`--dart-define=HOSTED_PREVIEW=true` so Device Preview can show its iPhone 16
frame. Device Preview 3 disables simulation in release builds. The hosted
preview does not include a live Flutter DevTools device selector and is not
an actual iOS simulator. All data remains illustrative and resets on reload.

To reproduce the hosted build:

```sh
flutter build web --profile --dart-define=HOSTED_PREVIEW=true --base-href /veritas_prototype-0.1/
```

For a normal production web build without the simulated device:

```sh
flutter build web --release --base-href /veritas_prototype-0.1/
```
