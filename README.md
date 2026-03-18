<div align="center">

# FitNexora (v2.0)
### The Ultimate AI-Driven Gym Management SaaS Ecosystem

*Engineered for India & Emerging Markets • Powered by Claude 4.5 & Supabase*

[![Full Tech Stack](https://img.shields.io/badge/Stack-Flutter_|_Supabase_|_Claude-blueviolet.svg)](#02--technical-deep-dive)
[![Market](https://img.shields.io/badge/Focus-India_SaaS-orange.svg)](#05--indian-market-localization)
[![Security](https://img.shields.io/badge/Security-RLS_Isolated-green.svg)](#03--multi-tenant-data-architecture)

</div>

---

## 01 — Mission & Value Proposition

**FitNexora** is not just a CRM; it is a **Business Intelligence and Automated Coaching Platform**. 

In the emerging fitness markets, gym owners face a "coaching gap"—they have the space, but lack the high-quality, personalized guidance that keeps members retained. FitNexora fills this gap by utilizing **Elite-tier AI** to provide professional-grade workout and nutrition coaching at a fraction of the cost of a human specialist.

---

## 02 — Technical Deep-Dive

### The AI Engine (Claude 4.5 Integration)
The system utilizes a **Tier-Aware Model Router** (`claude_service.dart`) that manages performance vs. cost:
- **Claude Opus (Elite)**: Reserved for high-complexity reasoning (Full 12-week periodization plans, intricate progress analysis, business forecasting).
- **Claude Haiku (Pro/Flash)**: Used for instantaneous micro-interactions (Exercise substitutions, nutrition Q&A, supplement advice).
- **Context Injection**: The `AiPromptBuilder` synthesizes client medical history, equipment availability, regional diet types, and gym-specific equipment lists into a 4,000+ token context window.

### Frontend Architecture
Built with **Flutter 3.6.1**, following a **Feature-First Layered Architecture**:
- **State Management**: `Riverpod 2.6` for reactive, compile-safe state providers and mock-data injection for offline developer by-pass testing.
- **Routing**: `GoRouter` for deep-linking, hierarchical navigation, and role-based redirect interception.
- **Theming & UI**: Complete systemic Dark Mode and Light Mode support via a custom `ThemeProvider`.
- **Animations**: `flutter_animate` for high-end micro-interactions and glassmorphism UI.
- **Charts**: `fl_chart` for real-time traffic and revenue visualization.

---

## 03 — Multi-Tenant Data Architecture

FitNexora implements a **Hard Isolation Strategy** using PostgreSQL Row-Level Security (RLS). 

### Database Schema Overview
The system is built on 12+ core migration modules:
1.  **`gyms`**: Master tenant records.
2.  **`gym_members`**: Link table with role-based permissions (`owner`, `trainer`, `client`).
3.  **`clients`**: Detailed profiles including injury history, metrics, and goals.
4.  **`memberships`**: Subscription records for gym members (Active, Expiring, Expired).
5.  **`subscriptions`**: SaaS tiering for the gym owner (Basic, Pro, Elite).
6.  **`ai_usage`**: Tracking tokens and model calls per tenant for quota enforcement.
7.  **`gym_checkins`**: Real-time traffic logging for heatmaps.
8.  **`food_logs`**: Detailed nutrition tracking with macro calculation boundaries.
9.  **`workout_plans` / `diet_plans`**: Versioned, AI-generated plans.
10. **`health_tracking`**: Daily aggregates for Steps, Sleep, and Activity metrics.
11. **`journals`**: Encrypted daily notes and progress markers.
12. **`notifications`**: Personalized push and in-app alert tracking.
13. **`body_measurements`**: Tracking metrics like BMI, Body Fat, and Muscle Mass.
14. **`water_logs`**: Hydration tracking and goal enforcement.
15. **`personal_records`**: Exercise-specific PR logging (Weight, Reps, Notes).
16. **`notification_preferences`**: User-specific opt-ins for multiple alert categories.
17. **`equipment_status`**: Material tracking for gym facilities.
18. **`todos`**: Role-based task management for trainers and owners.

### RLS Enforcement
Every single SQL query is appended with a `gym_id` check at the database level. Even if a user attempts to manually query an ID from another gym, the database returns zero results.

---

## 04 — The Domain Model (Enums & States)

The application logic is driven by a comprehensive set of domain enums:

| Domain | Values |
|---|---|
| **User Roles** | `superAdmin`, `gymOwner`, `trainer`, `client` |
| **SaaS Tiers** | `Basic` (No AI), `Pro` (Haiku AI), `Elite` (Opus AI + Chat) |
| **Fitness Goals** | `fatLoss`, `muscleGain`, `maintenance`, `rehab`, `sportSpecific` |
| **Dietary Types** | `Veg`, `Non-Veg`, `Jain`, `Keto`, `Vegan`, `Intermittent Fasting` |
| **Experience** | `Beginner`, `Intermediate`, `Advanced`, `Athlete` |
| **Trends** | `Losing Fast`, `On Track`, `Stalling`, `Fluctuating` |
| **Theme Modes** | `Light`, `Dark`, `System` |

---

## 05 — Indian Market Localization

FitNexora is natively built for the Indian ecosystem:
- **Regional Languages**: Full support for Hindi, Hinglish, Marathi, and Tamil.
- **GST Ready**: Automated tax calculation (18% GST) on all member invoices.
- **UPI Integration**: Native Razorpay flow optimized for mobile-first payments.
- **Cuisine Support**: Pre-configured for Indian food databases (Dal, Paneer, regional breakfast items).

---

## 06 — Core Features & Modules

The platform is divided into comprehensive modules designed to drive member engagement and retention:
- **AI-Driven Workouts & Diet**: Elite-tier contextual coaching powered by Claude 4.5.
- **Achievements Hub**: Gamified milestone tracking and performance rewards.
- **Interactive Workout Calendars**: Visual progress and session history tracking.
- **Active Session Tracking**: Real-time workout mode with integrated rest timers and PR alerts.
- **Health & Vit Stats**: Comprehensive modules for **Step Tracking**, **Sleep Analysis**, **Hydration**, and **Body Measurements (BMI/Body Fat)**.
- **Performance Record (PR) System**: Benchmarking exercise-specific milestones across all training cycles.
- **Elite Training Tools**: Specialized calculators for **1RM (One Rep Max)** and **Nutrient Macros**.
- **Trainer Task Management**: Contextual todo lists for owners and trainers to manage gym operations.
- **Live Gym Intelligence**: Real-time traffic heatmaps and **Equipment Status** monitoring.
- **Notes & Journaling**: Secure, encrypted private journaling for members.
- **Real-Time Notifications**: Multi-channel alerts with granular unread badge tracking.
- **Systemic Theming**: Fully responsive **Dark Mode** & Light Mode interfaces customized securely via user preferences.
- **Offline Development & Bypasses**: Advanced developer bypass endpoints with intelligent mock data injection.

---

## 07 — Developer & DevOps Guide

### Deployment & Configuration
- **Supabase Edge Functions**: Handles high-security operations (payment webhooks, token management).
- **Environment Management**: `.env` system for Claude API keys and Supabase Anon/Service roles.

### Complete Setup Workflow
```bash
# 1. Environment Initialization
git clone https://github.com/vijaysinghkadela/Fit_Nexora.git
flutter pub get

# 2. Database Synchronization (Supabase)
supabase login
supabase link --project-ref your-project-id
supabase db push

# 3. Code Generation (Models & L10n)
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# 4. Native Assets (Splash & Icons)
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons
```

---

## 08 — Future Roadmap (v3.0)
- [ ] **AI Video Analysis**: Real-time form correction using device camera.
- [ ] **WhatsApp Bot**: Command-line interface for members to log food via WhatsApp.
- [ ] **Trainer Marketplace**: Platform-wide hiring for certified specialists.

---

## 09 — Contributors & Contact

- **Lead Developer**: Vinay Pal / Vijay Singh Kadela
- **Architecture**: Fit_Nexora Core Team
- **Support**: dev@fitnexora.com

*This documentation is strictly based on the FitNexora v2.1 Production Specifications.*