# GymOS AI — Claude Code Master Brief

## Project Overview
Flutter + Supabase SaaS gym-management app called **FitNexora** (`gymos_ai`).
- State: `flutter_riverpod` + `StateNotifier`
- Routing: `go_router` (all routes in `lib/config/routes.dart`)
- Theme: `FitNexoraThemeTokens` extension (dark + light), toggled in Settings
- Backend: Supabase (URL + anon key in `.env`)
- Payments: Razorpay

## Roles & Home Routes
| Role | Home |
|------|------|
| `superAdmin` | `/admin` |
| `gymOwner` | `/dashboard` |
| `trainer` | `/trainer` |
| `client` | `/member` |

---

## ✅ Completed (pre-applied to codebase)

### New Models (`lib/models/`)
- `body_measurement_model.dart` — weight, BMI, body fat, measurements
- `water_log_model.dart` + `WaterTrackerState`
- `personal_record_model.dart` — exercise PRs + Epley 1RM estimate
- `achievement_model.dart` — 12 seeded achievements with XP system

### New Providers (`lib/providers/`)
- `body_measurement_provider.dart` — Supabase CRUD, optimistic updates
- `water_tracker_provider.dart` — daily log + goal persistence
- `personal_records_provider.dart` — CRUD + best-per-exercise aggregation
- `achievement_provider.dart` — local XP + level system

### New Screens (`lib/screens/`)
- `health/body_measurements_screen.dart` — log/view/delete measurements
- `health/water_tracker_screen.dart` — quick-add, daily goal, log history
- `workouts/personal_records_screen.dart` — Hall of Fame + full history
- `achievements/achievements_screen.dart` — XP level + unlocked/locked grid
- `tools/macro_calculator_screen.dart` — TDEE + macro breakdown (Mifflin)
- `tools/one_rep_max_screen.dart` — Epley/Brzycki/Lombardi/Mayhew + % table

### Routes added to `lib/config/routes.dart`
```
/health/body-measurements
/health/water
/workout/personal-records
/achievements
/tools/macro-calculator
/tools/one-rep-max
```

### Supabase Migration
`supabase/migrations/011_new_features.sql` — creates:
- `body_measurements` table with RLS
- `water_logs` table with RLS
- `personal_records` table with RLS
- `equipment_status` table with RLS
- `notification_preferences` table with RLS
- `gym_current_occupancy` view

### New Dependencies in `pubspec.yaml`
- `flutter_local_notifications: ^17.2.4`
- `connectivity_plus: ^6.1.1`
- `table_calendar: ^3.1.3`
- `percent_indicator: ^4.2.3`
- `lottie: ^3.1.2`
- `image_picker: ^1.1.2`
- `permission_handler: ^11.3.1`
- `mobile_scanner: ^5.2.3`

---

## 🔧 Tasks for Claude Code to Complete

### PRIORITY 1 — Wire new screens into existing navigation

**Member Home Screen** (`lib/screens/member/member_home_screen.dart`):
Add navigation cards/buttons for the new features:
```dart
// Add these tappable cards to the member home grid/list:
context.go('/health/body-measurements')  // 📏 Body Measurements
context.go('/health/water')              // 💧 Hydration
context.go('/workout/personal-records')  // 🏆 Personal Records
context.go('/achievements')              // ⚡ Achievements
context.go('/tools/macro-calculator')    // 🥗 Macro Calculator
context.go('/tools/one-rep-max')         // 💪 1RM Calculator
```

**Dashboard Screen** (`lib/screens/dashboard/dashboard_screen.dart`):
Add quick-stat cards for gym owner: current occupancy (use `gym_current_occupancy` view), equipment status summary.

### PRIORITY 2 — Local Push Notifications Service

Create `lib/services/notification_service.dart`:
```dart
// Use flutter_local_notifications
// Schedule daily reminders:
// 1. Membership expiry warning (7 days before)
// 2. Daily water reminder at 10 AM if hydration < 50%
// 3. Workout reminder at user's chosen time
// Initialize in main.dart after app init
```

### PRIORITY 3 — Equipment Status Screen

Create `lib/screens/gym/equipment_status_screen.dart`:
- List equipment from Supabase `equipment_status` table
- Show available / in-use / out-of-service counts with colour coding
- Gym owners can update `in_use` and `out_of_service` counts
- Members see read-only availability at a glance
- Route: `/gym/equipment`

Add to routes.dart:
```dart
GoRoute(
  path: '/gym/equipment',
  name: 'equipment-status',
  pageBuilder: (c, s) => _fadePage(s, const EquipmentStatusScreen()),
),
```

### PRIORITY 4 — Performance Optimization

**`lib/widgets/glassmorphic_card.dart`** — ensure `applyBlur` parameter skips
`BackdropFilter` when `performanceProvider` is true. Check every usage.

**Image caching** — add to `main.dart`:
```dart
PaintingBinding.instance.imageCache.maximumSize = 50;      // max 50 images
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
```

**Lazy providers** — convert heavy providers to `.autoDispose`:
```dart
// Example:
final bodyMeasurementProvider = StateNotifierProvider.autoDispose<...>
```

**List views** — replace any `ListView(children: [...])` with
`ListView.builder` or `SliverList.builder` for long lists.

**RepaintBoundary** — wrap every chart widget (`fl_chart`) and
`CircularGauge` in `RepaintBoundary(child: ...)`.

### PRIORITY 5 — Dark/Light Mode Verification

Open every screen and confirm it uses `context.fitTheme` (the
`FitNexoraThemeTokens` extension) for ALL colours — never hardcoded hex.
Fix any screen that uses `Colors.white` or `Colors.black` directly.

Pattern to find and fix:
```bash
grep -r "Colors.white\|Colors.black\|Color(0xFF" lib/screens --include="*.dart" -l
```
Replace hardcoded colours with theme tokens:
- `Colors.white` → `t.textPrimary` or `Colors.white` only for icon foreground
- Background colours → `t.background` / `t.surface`
- Text → `t.textPrimary` / `t.textSecondary` / `t.textMuted`

### PRIORITY 6 — Navigation Bar Consistency

All member-facing screens should show a consistent bottom nav bar with tabs:
**Home · Workouts · Nutrition · Progress · Profile**

Create `lib/widgets/member_bottom_nav.dart` — a `ConsumerWidget` that:
- Highlights the active route using `GoRouter.of(context).state.matchedLocation`
- Uses `context.go(route)` for navigation
- Respects `performanceProvider` for surface blur

### PRIORITY 7 — QR Check-In Screen for Gym Members

Create `lib/screens/gym/qr_checkin_screen.dart`:
- Use `mobile_scanner` to scan a gym-specific QR code
- QR payload = `gym_id`
- On successful scan, call Supabase `gym_checkins` insert
- Show success animation (use `flutter_animate`)
- Route: `/gym/checkin`

---

## 🐛 Known Issues to Fix

1. **Settings screen** — "Personal Info" tap shows `showSnackBar('Profile editing will be wired next.')`.
   Wire up a proper profile edit bottom sheet (name, phone, avatar via `image_picker`).

2. **`/clients/checkin` route** — verify `LogCheckinScreen` handles the case where
   no gym is selected gracefully (show error, redirect to `/dashboard`).

3. **Error boundary in routes.dart** — `AppColors.bgDark` is hardcoded dark.
   Replace with `Theme.of(context).scaffoldBackgroundColor` so it respects light mode.

4. **`master_perks_screen.dart`** — confirm route `/master/perks` is navigable from
   `MasterHomeScreen`. Add missing navigation entry if absent.

5. **`trainer_dashboard_screen.dart`** — add a bottom nav bar (Home / Clients / Schedule / Profile)
   matching the design language of `DashboardScreen`.

---

## 📐 Code Style Rules

- Use `context.fitTheme` (never `Theme.of(context).colorScheme.primary` directly)
- Use `GoogleFonts.inter(...)` for all text
- All cards: `GlassmorphicCard(borderRadius: 24, applyBlur: !isLowPerf, child: ...)`
- Animations: `flutter_animate` with `.animate().fadeIn(duration: 300.ms)`
- State: `ConsumerWidget` or `ConsumerStatefulWidget` with `ref.watch(provider)`
- No `print()` statements — use `debugPrint()` only in debug mode
- All Supabase calls wrapped in try/catch with optimistic UI updates

---

## 🚀 Run Commands

```bash
# Install new deps
flutter pub get

# Run migration against Supabase
supabase db push   # or apply 011_new_features.sql in Supabase dashboard SQL editor

# Run app
flutter run

# Check for analysis issues
flutter analyze

# Build release APK
flutter build apk --release --target-platform android-arm64
```

---

## 🧠 RAM Optimization Checklist (4–6 GB devices)

- [x] `performanceProvider` — disables blurs & shadows
- [ ] Set image cache limits in `main.dart` (see Priority 4)
- [ ] Convert expensive providers to `.autoDispose`
- [ ] Use `const` constructors everywhere possible
- [ ] Wrap all charts in `RepaintBoundary`
- [ ] Use `ListView.builder` not `ListView(children:[...])`
- [ ] Dispose all `TextEditingController`, `AnimationController` in `dispose()`
- [ ] Load Google Fonts from cache only: set `GoogleFonts.config.allowRuntimeFetching = false;` after first run
- [ ] Use `CachedNetworkImage` for all remote images (already a dep)
- [ ] Avoid `setState` in build — use `ref.watch` + Riverpod providers

---

*Generated by Claude — GymOS AI v2.5*
