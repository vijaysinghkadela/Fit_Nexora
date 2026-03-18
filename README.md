<div align="center">

<br/>

# 🏋️ FitNexora
### AI-Powered Gym Management SaaS Platform

*Built for India & Emerging Markets · Powered by Claude AI & Supabase*

[![Flutter](https://img.shields.io/badge/Flutter-3.6+-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com)
[![Claude AI](https://img.shields.io/badge/AI-Claude_Opus_%26_Haiku-blueviolet)](https://anthropic.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_2.6-orange)](https://riverpod.dev)

</div>

---

## 📋 Table of Contents

1. [Project Overview](#01--project-overview)
2. [SaaS Tiers & Pricing](#02--saas-tiers--pricing)
3. [Architecture](#03--architecture)
4. [AI Engine](#04--ai-engine)
5. [Database Schema](#05--database-schema)
6. [Screen Modules](#06--screen-modules)
7. [Role-Based Access](#07--role-based-access)
8. [Indian Market Features](#08--indian-market-features)
9. [Domain Model (Enums)](#09--domain-model-enums)
10. [Developer Guide](#10--developer-guide)
11. [Roadmap](#11--roadmap)
12. [Team](#12--team)

---

## 01 — Project Overview

**FitNexora** is a full-stack, multi-tenant SaaS platform that transforms how gym owners manage their business. Unlike traditional gym CRMs, FitNexora embeds a **tiered AI coaching engine** (Claude Opus & Haiku) directly into the platform, providing professional-grade, personalized workout and nutrition plans to every member at scale.

### The Problem
Gym owners in India and emerging markets face a "coaching gap" — they have the space, equipment, and clients, but lack the bandwidth to deliver high-quality, personalized coaching that keeps members retained. Hiring specialist trainers is expensive; generic printed plans don't work.

### The Solution
FitNexora closes this gap by:
- **Automating personalized coaching** via AI trained on the client's goals, injuries, diet, and history
- **Giving owners full business intelligence** — churn prediction, revenue forecasting, peak hour analysis
- **Providing trainers operational tools** — client management, workout assignment, commission tracking
- **Engaging members directly** — a dedicated member app with progress tracking, achievements, and AI chat

---

## 02 — SaaS Tiers & Pricing

FitNexora operates on a **3-tier SaaS model**:

| Feature | 🥉 Basic | 🥈 Pro | 🥇 Elite |
|---|---|---|---|
| **Monthly Price** | $9.99/mo | $19.99/mo | $29.99/mo |
| **Annual Price** | $99.99/yr | $199.99/yr | $299.99/yr |
| **Max Clients** | 50 | 200 | 500 |
| **Trainer Seats** | 1 | 5 | Unlimited |
| **AI Model** | ❌ None | ✅ Claude Haiku | ✅ Claude Opus + Haiku |
| **Monthly AI Calls** | 0 | 100 Haiku | 50 Opus + Unlimited Haiku |
| **AI Token Budget** | 0 | 500K tokens | 2M tokens |
| **Free Trial** | ❌ | ✅ 14 days | ✅ 14 days |

### Plan Feature Matrix (22-feature competitive gap)

**Basic includes:** Client management, membership tracking, dashboard, expiry alerts, manual workout plans, GST invoice generator, UPI/Razorpay, Hindi language support, offline mode.

**Pro adds:** Claude Haiku AI suggestions, Indian food database, supplement advisor, diet plans, trainer management, streak system, gym leaderboard, milestone rewards, progress tracking, attendance & payment tracking, at-risk client alerts, WhatsApp notifications, broadcast messaging.

**Elite exclusively:** Claude Opus coaching, AI live chat, agent performance scoring, video messaging, MRR/churn dashboard, revenue forecasting, peak-hours heatmap, advanced analytics, multi-gym support, white-label, custom templates, API access, priority support.

---

## 03 — Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (Client)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │  Screens │  │ Providers│  │ Services │  │  Widgets   │  │
│  │  (24 mod)│  │(Riverpod)│  │ (9 svc)  │  │(18 shared) │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────────┘  │
└───────┼─────────────┼─────────────┼────────────────────────┘
        │             │             │
        ▼             ▼             ▼
┌───────────────────────────────────────────────────────────┐
│                   Supabase Backend                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │PostgreSQL│  │   Auth   │  │ Storage  │               │
│  │ + RLS    │  │  (JWT)   │  │(Avatars) │               │
│  └──────────┘  └──────────┘  └──────────┘               │
└──────────────────────────────┬────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Claude AI API     │
                    │  (Opus + Haiku)      │
                    └─────────────────────┘
```

### Frontend Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.6+ (Dart) |
| State Management | Riverpod 2.6 (compile-safe, reactive) |
| Routing | GoRouter (deep-linking, role-based redirect) |
| Theming | Custom `ThemeProvider` — Dark/Light/System |
| Animations | `flutter_animate` (micro-interactions, glassmorphism) |
| Charts | `fl_chart` (revenue, traffic, progress) |
| Fonts | Google Fonts (Inter, Poppins) |
| Localisation | Flutter `l10n` (English, Hindi, Hinglish) |
| Payments | Razorpay (India), Stripe (global) |

### Folder Structure

```
lib/
├── app.dart                   # Root app widget
├── main.dart                  # Entry point, env loading
├── config/
│   ├── app_config.dart        # Env vars (Supabase, Stripe, Claude keys)
│   ├── plan_limits.dart       # Single source of truth for SaaS limits
│   ├── routes.dart            # GoRouter config, role-based guards
│   ├── theme.dart             # Design tokens, color palettes
│   └── ai_system_prompt.txt   # Master Claude system prompt
├── core/
│   ├── enums.dart             # All domain enums (15+ enums)
│   ├── access_control.dart    # Feature gate logic
│   ├── validators.dart        # Form validation
│   ├── pagination.dart        # Cursor-based paginated controllers
│   ├── dev_bypass.dart        # Mock data for offline dev
│   └── extensions.dart        # Dart extension methods
├── models/                    # 18 data models
├── providers/                 # 21 Riverpod providers
├── screens/                   # 24 screen modules
├── services/                  # 9 backend services
└── widgets/                   # 18 shared UI components
```

---

## 04 — AI Engine

### Tier-Aware Model Router (`claude_service.dart`)

The AI engine uses a smart routing system to balance performance and cost:

```
Request → PlanLimits.canMakeAiCall() → Decision
   ├── Basic:      DENIED (upgrade wall)
   ├── Pro:        → Claude Haiku (fast, cost-efficient)
   └── Elite:
        ├── Within 50 Opus calls → Claude Opus (best reasoning)
        ├── Opus cap exceeded   → Auto-downgrade to Haiku
        └── Overage enabled     → Metered billing ($0.10/call)
```

### Context Injection (`ai_prompt_builder.dart`)

Every AI call is enriched with a **4,000+ token context window** synthesized from:

- 👤 Client profile (age, weight, height, fitness goal, training level)
- 🩺 Medical history (injuries, stress level, health conditions)
- 🍽️ Dietary preferences (10 diet types — Veg, Jain, Keto, IF, etc.)
- 🏋️ Equipment availability (Full gym, home, bodyweight only)
- 🕐 Training schedule (morning / afternoon / evening preference)
- 🥘 Cuisine type & cooking capability (Indian, western, mixed)
- 📍 Regional context (Indian food database, local supplement brands)

### AI Capabilities by Screen

| Module | AI Feature | Tier |
|---|---|---|
| Elite Home | Personalized welcome + daily coaching tip | Elite |
| AI Trainer | Full 12-week periodization plan | Elite (Opus) |
| Elite Chat | Live multi-turn AI coaching conversation | Elite |
| Supplements | AI supplement stack recommendations | Pro + Elite |
| Diet Plan | Custom macro-based meal plans | Pro + Elite |
| Progress | AI-driven trend analysis & adjustment | Elite |
| Pro AI Screen | Haiku-based quick coaching suggestions | Pro |

---

## 05 — Database Schema

FitNexora uses **18 PostgreSQL migration modules** on Supabase with full Row-Level Security (RLS) enforcement at the database layer:

### Core Tables

| # | Table | Purpose |
|---|---|---|
| 1 | `gyms` | Master tenant records; each gym is an isolated tenant |
| 2 | `gym_members` | Link table — user → gym with role (`owner`, `trainer`, `client`) |
| 3 | `clients` | Detailed client profiles (injury history, goals, metrics) |
| 4 | `memberships` | Member subscription records (Active, Expired, Paused, Cancelled) |
| 5 | `subscriptions` | Gym-level SaaS plan (Basic / Pro / Elite) + billing data |
| 6 | `ai_usage` | Token and call tracking per tenant for quota enforcement |
| 7 | `gym_checkins` | Real-time traffic logging with `checked_in_at` + `checkout_at` |
| 8 | `food_logs` | Detailed nutrition tracking with macro calculation |
| 9 | `workout_plans` | Versioned, AI-generated workout programs |
| 10 | `diet_plans` | Versioned AI-generated meal plans |
| 11 | `health_tracking` | Daily aggregates (Steps, Sleep, Activity) |
| 12 | `journals` | Private encrypted daily member notes |
| 13 | `notifications` | In-app and push notification records |

### Extension Tables (Migration 011+)

| # | Table | Purpose |
|---|---|---|
| 14 | `body_measurements` | BMI, Body Fat %, Muscle Mass, waist/hip/arm/thigh measurements |
| 15 | `water_logs` | Per-day hydration tracking (ml), goal enforcement |
| 16 | `personal_records` | Exercise-specific PRs (exercise name, weight, reps, date) |
| 17 | `notification_preferences` | Per-user opt-in for each notification category |
| 18 | `equipment_status` | Gym equipment inventory (units, in-use, out-of-service) |
| 19 | `todos` | Role-based task management for trainers and owners |

### Views

| View | Purpose |
|---|---|
| `gym_current_occupancy` | Real-time member count per gym (checked in, not checked out, last 12h) |

### RLS Strategy

Every query is enforced at the **database level** with `gym_id` isolation. Even if a user guesses another gym's UUID, Supabase RLS returns zero results. No gym can ever access another gym's data.

---

## 06 — Screen Modules

FitNexora has **24 screen modules** organised by role and feature:

### 🔐 Auth
Login, Register, Forgot Password, Onboarding wizard.

### 🏠 Dashboard
Role-adaptive home screen with KPIs, quick actions, and AI-suggested insights.

### 👤 Clients (Owner/Trainer)
Full CRUD client management — profile creation, plan assignment, membership tracking, goal setting, injury history, and medical flags.

### 📋 Memberships
Membership lifecycle management — create, renew, pause, cancel. GST invoice generation, payment tracking.

### 🥇 Elite Member Portal
Premium member-facing screens for Elite gym subscriptions:
- **Elite Home** — AI daily coaching brief + streak
- **Elite AI Trainer** — Full periodization workout plan (Claude Opus)
- **Elite Chat** — Real-time AI coaching conversation
- **Elite Supplements** — AI supplement advisor
- **Elite Muscle Progress** — Body composition trend charts

### 💎 Pro Member Portal
AI-enhanced screens for Pro subscriptions:
- **Pro Home** — Dashboard with nutrition & workout summary
- **Pro AI Screen** — Haiku-powered quick coaching
- **Pro Nutrition** — Macro tracking with AI meal suggestions
- **Pro Measurements** — Body stat logging and trend charting

### 👤 Member Portal (All tiers)
- **Member Home** — Workout & diet summary
- **Member Workouts** — Today's plan + history
- **Member Diet** — Food log & macro balance
- **Member Progress** — Progress check-ins & photo uploads
- **Member Announcements** — Gym broadcast messages

### 🏋️ Workouts
- **Workouts Screen** — Browse & filter workout templates
- **Active Workout** — Live session tracker with set/rep logging
- **Workout Calendar** — Visual monthly session timeline
- **Workout History** — Past sessions with volume metrics
- **Personal Records** — PR board with exercise-specific bests
- **Exercise Progress** — Volume/strength progression charts
- **Compare Exercises** — Side-by-side exercise comparison
- **Rest Timer** — Configurable countdown timer
- **Workout Completion** — Session summary with AI feedback

### ❤️ Health & Vitals
- **Body Measurements** — BMI, body fat, and tape measurements over time
- **Water Tracker** — Daily hydration goal with ml logging
- **Steps Tracking** — Step count & distance over time
- **Sleep Tracking** — Duration, quality ratings, trend analysis

### 🏆 Achievements
Gamified milestone system with badges and streak tracking.

### 🧮 Elite Training Tools
- **Macro Calculator** — Personalised TDEE + macro split
- **1RM Calculator** — One-rep max estimator with multiple formulas

### 📊 Traffic & Analytics
- Real-time gym occupancy heatmap
- Peak hours analysis chart

### 🏗️ Gym Operations
- **Equipment Status** — Live equipment availability board

### 📝 Notes & Journals
Private encrypted member notes and journaling.

### 🔔 Notifications
In-app notification center with unread count badge.

### 🍽️ Nutrition (Standalone)
Full food log with barcode search and Indian food database.

### 🎟️ Subscription
Plan upgrade/downgrade with pricing comparison UI.

### ✅ Todos (Trainer/Owner)
Task management with priority (High/Medium/Low) and status (Todo / In Progress / Done).

### ⚙️ Settings
Language, theme, notification preferences, account management.

### 🛡️ Admin / Super Admin
Platform-wide gym management (for FitNexora staff).

### 💬 Support
In-app support request flow.

---

## 07 — Role-Based Access

The app has **4 user roles** with fully segregated navigation and feature access:

| Role | Access |
|---|---|
| `superAdmin` | Full platform admin — manage all gyms |
| `gymOwner` | Business owner — full gym + member management, billing, analytics |
| `trainer` | Enrolled staff — manage assigned clients, workout plans, todos |
| `client` | Member — personal dashboard, workouts, diet, tracking, AI coaching |

Role detection drives:
1. **GoRouter redirects** (role-based route guards in `routes.dart`)
2. **Sidebar navigation** (`sidebar_nav.dart`) — different nav items per role
3. **Feature gates** (`access_control.dart` + `plan_limits.dart`) — premium features behind plan walls

---

## 08 — Indian Market Features

FitNexora is natively built for the Indian fitness market:

| Feature | Details |
|---|---|
| 🇮🇳 **GST Billing** | Automated 18% GST calculation on all invoices |
| 💳 **UPI Payments** | Native Razorpay flow optimised for UPI and mobile wallets |
| 🥘 **Indian Food DB** | Pre-configured food database covering Dal, Paneer, Roti, regional breakfasts |
| 🗣️ **Language Support** | English, Hindi, Hinglish localisation via Flutter `l10n` |
| 🧘 **Jain & Vegan Diets** | Full diet type support including Jain, Veg, Lacto-Veg, Diabetic-Friendly |
| 🌐 **Offline Dev Bypass** | Local mock data in `dev_bypass.dart` for development without network |

---

## 09 — Domain Model (Enums)

The application logic is driven by type-safe Dart enums (`lib/core/enums.dart`):

| Enum | Values |
|---|---|
| `UserRole` | `superAdmin`, `gymOwner`, `trainer`, `client` |
| `PlanTier` | `basic`, `pro`, `elite` |
| `MembershipStatus` | `active`, `expired`, `cancelled`, `paused` |
| `SubscriptionStatus` | `active`, `pastDue`, `cancelled`, `trialing` |
| `FitnessGoal` | `fatLoss`, `muscleGain`, `maintenance`, `athleticPerformance`, `generalFitness`, `rehabilitation`, `sportSpecific` |
| `TrainingLevel` | `beginner`, `intermediate`, `advanced`, `athlete` |
| `EquipmentType` | `fullGym`, `homeWithEquipment`, `homeMinimal`, `bodyweightOnly` |
| `DietType` | `nonVeg`, `veg`, `lactoVeg`, `vegan`, `jain`, `keto`, `intermittentFasting`, `diabeticFriendly`, `lowCarb`, `other` |
| `TrainingTime` | `morning`, `afternoon`, `evening` |
| `WeightTrend` | `losingFast`, `losingSlow`, `onTrack`, `stalling`, `gaining`, `fluctuating` |
| `QualityRating` | `poor`, `average`, `good`, `excellent` |
| `LanguagePreference` | `english`, `hindi`, `hinglish` |
| `StressLevel` | `low`, `moderate`, `high`, `veryHigh` |
| `CuisineType` | `indian`, `mixed`, `western` |
| `CookingLevel` | `fullCooking`, `partial`, `minimal`, `none` |

---

## 10 — Developer Guide

### Prerequisites

- Flutter 3.6+ with Dart 3.x
- Supabase account
- Anthropic Claude API key
- Razorpay account (for Indian payments)
- Java JDK 17+ (for Android builds)

### Environment Setup

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
CLAUDE_API_KEY=your-anthropic-api-key
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-secret
STRIPE_PUBLISHABLE_KEY=your-stripe-pk
STRIPE_SECRET_KEY=your-stripe-sk
```

### Setup Workflow

```bash
# 1. Clone and install dependencies
git clone https://github.com/vijaysinghkadela/Fit_Nexora.git
cd Fit_Nexora
flutter pub get

# 2. Push database schema (Supabase)
supabase login
supabase link --project-ref your-project-id
supabase db push

# 3. Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Native assets (splash & icons)
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons

# 5. Run the app
flutter run
```

### Offline Development (No Backend Required)

The `dev_bypass.dart` module provides full mock data injection. Set the bypass flag to `true` to run the app without any Supabase or Claude credentials — ideal for UI development and testing.

### Key Services

| Service | Responsibility |
|---|---|
| `auth_service.dart` | Supabase Auth (login, register, session management) |
| `database_service.dart` | All Supabase CRUD operations |
| `claude_service.dart` | Claude API calls with tier routing |
| `ai_prompt_builder.dart` | Context enrichment for AI prompts |
| `plan_enforcement_service.dart` | Feature gate checks at runtime |
| `payment_service.dart` | Razorpay & Stripe integration |
| `notification_service.dart` | Push & in-app notification dispatch |
| `food_service.dart` | Indian food database queries |
| `storage_service.dart` | Supabase Storage (avatar/photo uploads) |

### Running Tests

```bash
flutter test
```

---

## 11 — Roadmap

### v2.1 (Current)
- [x] Achievements & gamification
- [x] Body measurements & water tracking
- [x] Personal records (PR board)
- [x] Active workout session tracker
- [x] Trainer task management (todos)
- [x] Equipment status board
- [x] Real-time gym occupancy view

### v3.0 (Planned)
- [ ] **AI Video Form Analysis** — real-time posture & form correction using device camera
- [ ] **WhatsApp Bot Integration** — members log food & get plans via WhatsApp commands
- [ ] **Trainer Marketplace** — platform-wide hiring for certified specialists
- [ ] **Multi-Gym Dashboard** — unified Elite owner view across multiple branches
- [ ] **Offline-First Sync** — full offline mode with Supabase Realtime conflict resolution
- [ ] **Native Wearable Sync** — Google Fit / Apple Health integration

---

## 12 — Team

| Role | Contact |
|---|---|
| Lead Developer | **Vinay Pal / Vijay Singh Kadela** |
| Architecture | Fit_Nexora Core Team |
| Support | dev@fitnexora.com |
| Repository | [github.com/vijaysinghkadela/Fit_Nexora](https://github.com/vijaysinghkadela/Fit_Nexora) |

---

<div align="center">

*FitNexora v2.1 — Built with ❤️ for the Indian Fitness Industry*

</div>