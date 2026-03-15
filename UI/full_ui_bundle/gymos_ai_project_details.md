# GymOS AI / FitNexora Project Details

## 1) Project Summary

**GymOS AI** is a Flutter-based, AI-powered gym management SaaS platform. The repository README describes the product as **FitNexora**, a rebranded version of GymOS, aimed at gym owners, trainers, clients, and super admins. The app combines client management, memberships, AI-generated workout and diet plans, business analytics, attendance tracking, food logs, and subscription billing.

This project is built for a multi-tenant SaaS setup, which means each gym’s data is isolated from every other gym’s data. That is handled on the backend with Supabase and PostgreSQL Row Level Security (RLS). Because apparently one database is never enough, the code also includes plan enforcement, AI quota limits, and billing logic.

---

## 2) Product Goals

The app is designed to help gyms do all of the following in one system:

- Manage clients, trainers, memberships, and subscriptions
- Generate workout and nutrition plans using Claude-based AI
- Track progress, attendance, food logs, and gym traffic
- Send expiry alerts, announcements, and plan updates
- Support Indian-market requirements such as Hindi language support, GST invoices, and Razorpay integration
- Differentiate features by plan tier: Basic, Pro, and Elite

---

## 3) Technology Stack

### Frontend
- **Flutter 3.x**
- **Dart 3.6.1**
- **Riverpod** for state management
- **GoRouter** for navigation
- **flutter_animate** for motion/animation
- **fl_chart** for charts and analytics
- **flutter_localizations** and `intl` for localization

### Backend / Data
- **Supabase**
- **PostgreSQL**
- **Row Level Security (RLS)** for tenant isolation
- Storage buckets for avatars, gym logos, and progress photos

### AI and Automation
- **Claude API** integration
- Prompt-building service for plan generation
- AI usage tracking and quota enforcement

### Payments
- **Stripe** for global billing
- **Razorpay** for India-specific payments
- Subscription and invoice tables in the database

### Other Utilities
- `shared_preferences` for local persistence
- `cached_network_image`, `shimmer`, `flutter_svg`, `url_launcher`, `http`
- App icon and splash screen generation tools

---

## 4) Application Architecture

### Entry Flow
The app starts in `main.dart`:

1. Flutter bindings are initialized
2. `.env` is loaded
3. Supabase is initialized when credentials exist
4. The app is wrapped in:
   - `AppErrorBoundary`
   - `ProviderScope`
   - `GymOSApp`

### Root App Widget
`app.dart` creates a `MaterialApp.router` with:
- Dark theme by default
- Localization support
- Router configuration from Riverpod
- Supported languages:
  - English
  - Hindi
  - Bengali
  - Tamil
  - Telugu
  - Marathi

### Routing
The app uses `GoRouter` with auth guards:
- Public routes: `/`, `/login`, `/register`
- Authenticated users are redirected based on role
- Admin route is restricted to `superAdmin`
- Page transitions use a fade animation on selected routes

---

## 5) User Roles

The system supports four roles:

| Role | Access |
|---|---|
| **Super Admin** | Full platform access, revenue control, API cost control |
| **Gym Owner** | Own gym data, clients, trainers, memberships, analytics |
| **Trainer** | Assigned clients, plans, progress, communication |
| **Client** | Own workout/diet/progress data |

The role model is defined in `lib/core/enums.dart` and is used by routing, permissions, and data filtering.

---

## 6) Subscription Plan Tiers

The SaaS tiers are:

| Tier | Monthly Price | Client Limit | Trainer Limit | AI Access |
|---|---:|---:|---:|---|
| **Basic** | $9.99 | 50 | 1 | No AI |
| **Pro** | $19.99 | 200 | 5 | Claude Haiku only |
| **Elite** | $29.99 | 500 | Unlimited | Claude Opus + Haiku fallback |

### Important plan rules
- Basic has no AI access
- Pro is capped to Haiku and has strict monthly AI limits
- Elite gets Opus access with overage billing support
- Free trials are enabled for Pro and Elite
- Plan enforcement is defined in `lib/config/plan_limits.dart`

---

## 7) Core Features

### Client and Membership Management
- Add, edit, view, and manage clients
- Membership tracking and expiry handling
- Trainer assignment workflow
- Client progress tracking
- Attendance tracking
- Renewal and subscription management

### AI Features
- Workout plan generation
- Diet plan generation
- AI coaching screens for different tiers
- Supplement guidance
- Recovery and rest-day suggestions
- Progress-based adjustments
- AI usage metering and quota limits

### Business and Admin Tools
- Dashboard views
- Gym traffic tracking
- To-do management
- Analytics screens
- Subscription pricing page
- GST invoicing support
- Commission and trainer workload tracking

### Client-Facing Experience
- Workout, diet, and progress pages
- Announcements
- AI chat/coaching for higher tiers
- Plan request flows
- Responsive multi-role navigation

### Indian Market Support
- Hindi and other regional languages
- Razorpay support
- GST invoice support
- Indian food and diet assumptions in AI flows
- UPI-oriented payment support

---

## 8) Screens and UI Modules

### Authentication
- Splash screen
- Login screen
- Register screen
- Onboarding screen

### Dashboard and Admin
- Main dashboard
- Admin screen
- Trainer dashboard
- Settings screen

### Clients
- Clients list
- Add client
- Client details

### Memberships
- Memberships list
- Add membership

### Workouts and Nutrition
- Workouts screen
- Diet plans screen
- Nutrition screen

### Member Area
- Member home
- Workout
- Diet
- Progress
- Announcements
- Member paywall

### Pro Tier
- Pro home
- Pro AI screen
- Pro nutrition
- Pro measurements
- Pro paywall

### Elite Tier
- Elite home
- Elite AI trainer
- Elite chat
- Elite muscle progress
- Elite transformation
- Elite supplement
- Elite paywall

### Master Tier
- Master home
- Master AI coach
- Master analytics
- Master challenges
- Master live sessions
- Master recovery
- Master paywall

### Utility Screens
- Gym traffic
- To-dos
- Pricing

---

## 9) Project Structure

### `lib/config`
Contains app-wide configuration and theme-related files:
- `app_config.dart`
- `plan_limits.dart`
- `routes.dart`
- `theme.dart`
- `ai_system_prompt.txt`

### `lib/core`
Shared app logic and reusable constants:
- access control
- chart bucket logic
- constants
- database values
- enums
- error handling
- pagination
- responsive helpers
- validators

### `lib/models`
Data models for:
- users
- gyms
- clients
- memberships
- subscriptions
- workout plans
- diet plans
- food logs
- progress check-ins
- GST invoices
- announcements
- AI usage

### `lib/providers`
Riverpod providers for:
- auth
- gyms
- members
- elite/pro/master flows
- nutrition
- payments
- traffic
- locale
- client state

### `lib/screens`
All UI screens grouped by domain:
- auth
- dashboard
- clients
- memberships
- workouts
- nutrition
- member
- pro
- elite
- master
- admin
- settings
- traffic
- subscription
- todos

### `lib/services`
Backend and business-logic services:
- auth service
- database service
- Claude service
- AI prompt builder
- food service
- payment service
- storage service
- plan enforcement service

### `lib/widgets`
Reusable UI components:
- glassmorphic card
- stat card
- sidebar navigation
- subscription banner
- loading widgets
- error widgets
- AI usage meter
- dashboard sheet UI

---

## 10) Supabase Database Design

The repository contains a structured migration set under `supabase/migrations/`.

### Core tables
- `profiles`
- `gyms`
- `gym_members`
- `clients`
- `memberships`
- `subscriptions`

### AI and analytics tables
- `ai_usage`
- `workout_plans`
- `diet_plans`
- `progress_checkins`
- `trainer_assignments`

### Attendance and nutrition tables
- `gym_checkins`
- `food_logs`

### Billing tables
- `gst_invoices`

### Key design choices
- RLS is enabled on all sensitive tables
- Indexes are added for gym filtering, client filtering, expiry queries, and pagination
- Several migrations add columns for progress, sleep, energy, adherence, and language preference
- Subscription tables include Razorpay fields, trial fields, currency, and overage charges

---

## 11) Multi-Tenant Security Model

This project is clearly built for isolated gym data.

### Security approach
- Every important table uses **Row Level Security**
- Queries are scoped by `gym_id`
- Policies control access by role and membership relationship
- Trainers can access assigned clients, not the whole platform
- Clients can access only their own data
- Service-role policies are used for backend operations that need broader access

This is the correct design for SaaS isolation. Anything else would be reckless.

---

## 12) AI and Quota Enforcement

The app tracks AI usage so plan limits are not ignored like they usually are in hobby projects.

### AI-related logic includes:
- Monthly token limits
- Opus call caps
- Haiku call limits
- Basic plan AI denial
- Plan-based model routing
- Overage support only for Elite

### Behavior by tier
- **Basic**: no AI
- **Pro**: Haiku only, capped usage
- **Elite**: Opus plus fallback, with metered overage support

---

## 13) Localization and Market Reach

The app is not English-only.

### Supported locales
- `en`
- `hi`
- `bn`
- `ta`
- `te`
- `mr`

### Why this matters
The codebase is targeting Indian gyms and similar markets where:
- local language support matters
- payment habits differ
- GST invoicing matters
- diet recommendations should understand regional food patterns

---

## 14) Theme and Visual Style

The app uses a dark-first premium visual system with:
- violet primary color
- mint/emerald accent color
- glassmorphism-inspired components
- elevated surfaces for cards and panels
- Material 3 styling

The theme is defined in `lib/config/theme.dart` and enhanced by shared UI widgets like `glassmorphic_card.dart`.

---

## 15) Assets and Platform Support

### Assets
- App icon
- Logos
- Images folder

### Platforms
The project includes platform folders for:
- Android
- iOS
- Web
- Linux

That means this is a cross-platform Flutter app, not a single-platform toy.

---

## 16) Environment Variables

The project expects a `.env` file.

### Important keys
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `CLAUDE_API_KEY`

The app checks which services are configured before using them.

---

## 17) Setup Flow

Typical setup from the repository:

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Environment steps:
1. Copy `.env.example` to `.env`
2. Fill in keys and URLs
3. Connect Supabase
4. Generate localization files if needed

---

## 18) Testing and Quality

The repo includes tests for:
- chart bucket logic
- pagination
- food log model serialization
- membership model serialization
- dashboard widget sheet behavior

This shows the project is not just a UI shell. It has real structure and some validation around core logic.

---

## 19) Strengths of the Project

- Clear multi-role architecture
- Strong backend isolation with RLS
- Business-friendly SaaS plan enforcement
- AI integration tied to plan tiers
- Indian market features built in
- Organized Flutter structure with modular screens, models, services, and providers

---

## 20) Things to Watch

- The repository contains build artifacts and IDE folders, which should usually stay out of the final cleaned source package
- The README uses both **GymOS** and **FitNexora** naming, so branding should be unified
- Some features appear more advanced in documentation than in UI evidence, so the product description should stay consistent with actual implemented screens
- Secrets must never remain in version control. That `.env` situation is a classic way humans leak keys and then act surprised

---

## 21) Final Note

This project is a **Flutter + Supabase SaaS platform for gym management**, with AI coaching, localized billing, role-based access, and multi-tenant data control. It is structured as a scalable commercial product, not a simple demo app.

If you need this converted into a more formal **project report**, **college documentation**, or **README-style markdown**, this file can be reshaped into that format.
