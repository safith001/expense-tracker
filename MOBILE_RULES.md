# Mobile Tech & Runtime Rules

## 1. Core Framework & Runtime
- **Language & Framework:** Dart (3.x+) with Flutter (3.22+).
- **Target OS:** Android Only (minSdkVersion: 23, compileSdkVersion / targetSdkVersion: 34).
- **State Management:** Riverpod (`flutter_riverpod: ^2.5.1`) or standard `ChangeNotifier` Provider. Keep state logic decoupled from UI widgets.
- **Code Standards:** Strict Null Safety enabled. Absolutely NO web-only imports (`dart:html`) and NO arbitrary React/JS syntax.

## 2. Approved Dependency Manifest
Only the following libraries are approved for code generation:
- `sqflite: ^2.3.3+1` & `path: ^1.9.0` (Local database storage)
- `workmanager: ^0.5.2` (Background sync execution)
- `http: ^1.2.1` (REST payload delivery to Google Apps Script)
- `shared_preferences: ^2.2.3` (Settings, cached AI summary, preferences)
- `fl_chart: ^0.68.0` (Financial category donut charts)
- `intl: ^0.19.0` (Currencies and ISO-8601 date parsing)
- `google_fonts: ^6.2.1` (Typography: Plus Jakarta Sans)

## 3. UI/UX & Styling Constraints
- **Design System:** Material 3 (`useMaterial3: true`).
- **Color Palette:**
  - Background Light: Warm Cream (`#FAF9F6`)
  - Background Dark: Deep Slate (`#1A202C`)
  - Primary Accent: Soft Sage Green (`#5A7A6A`)
  - Secondary Accent / AI Badge: Dusty Lavender (`#805AD5`)
  - Text: Charcoal (`#2D3748`)
- **Shapes & Radii:** Card and modal corner radius strictly `16dp` to `22dp`.
- **Keyboard Handling:** Do not summon system virtual keyboards for transaction amount entry; use the custom built-in numeric pad bottom sheet to prevent layout shifting.