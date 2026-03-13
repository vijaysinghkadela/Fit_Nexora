<div align="center">
  
# GymOS
**Gym Management SaaS Platform**
  
*Full Application Architecture + Optimized AI — v2.0 (March 2026)*<br>
*Powered by Claude Opus · Built with Flutter*

</div>

---

## 01 — Application Overview

### Mission Statement
GymOS is a multi-tenant SaaS platform built for gym owners and trainers across India and emerging markets. It delivers AI-powered workout and diet plan generation, centralized client management, real-time business analytics, and automated revenue operations — at a price point accessible to independent gym operators.

### Core Technology Stack
| Layer | Technology | Purpose |
|---|---|---|
| **Frontend** | Flutter 3.x | Cross-platform: iOS, Android, Web |
| **Backend** | Node.js + Express | REST API, business logic |
| **Database** | PostgreSQL | Relational data, multi-tenant |
| **Cache** | Redis | Sessions, quota tracking, real-time |
| **AI Engine** | Claude Opus / Haiku | Plan generation, client chat |
| **Auth** | Supabase Auth | JWT, role-based access control |
| **Payments (Global)** | Stripe | Subscriptions, metered billing |
| **Payments (India)** | Razorpay | UPI, net banking, EMI |
| **Storage** | Cloudinary | Progress photos, video messages |
| **Notifications** | WhatsApp Business API | Alerts, renewals, broadcasts |
| **Monitoring** | Sentry + Datadog | Error tracking, API cost control |

### User Role Architecture
| Role | Access Scope | Primary Responsibility |
|---|---|---|
| **Super Admin** | Full platform | Revenue, churn, API cost control |
| **Gym Owner** | Own gym only | Clients, trainers, billing, analytics |
| **Trainer / Agent** | Assigned clients only | Plans, progress, communication |
| **Client** | Own profile only | View/modify plan, log progress, AI chat |

---

## 02 — Pricing Architecture

### Plan Comparison
| Feature | Basic $9.99 | Pro $19.99 | Elite $29.99 |
|---|---|---|---|
| **Client Cap** | 50 | 200 | 500 |
| **Trainer Seats** | 1 | 5 | Unlimited |
| **AI Model** | — | Claude Haiku | Claude Opus |
| **AI Quota/Month** | None | 100 generations | 50 Opus generations |
| **AI Workout Plans** | ❌ | ✅ | ✅ |
| **AI Diet Plans** | ❌ | ✅ | ✅ |
| **AI Client Chat** | ❌ | ❌ | ✅ |
| **WhatsApp Alerts** | ❌ | ✅ | ✅ |
| **Gamification** | ❌ | ✅ | ✅ |
| **At-Risk Alerts** | ❌ | ✅ | ✅ |
| **MRR Dashboard** | ❌ | ❌ | ✅ |
| **Revenue Forecast** | ❌ | ❌ | ✅ |
| **Trainer Scoring** | ❌ | ❌ | ✅ |
| **Peak Hour Heatmap** | ❌ | ❌ | ✅ |
| **White Label** | ❌ | ❌ | ✅ |
| **GST Invoicing** | ✅ | ✅ | ✅ |
| **Razorpay/UPI** | ✅ | ✅ | ✅ |
| **Hindi Support** | ✅ | ✅ | ✅ |
| **Offline Mode** | ✅ | ✅ | ✅ |

### Cost Protection Rules
- **Basic ($9.99/mo)**: Zero Claude API calls. Pure CRUD operations. Net margin after Stripe: ~$8.50/month per gym.
- **Pro ($19.99/mo)**: Claude Haiku only (~60x cheaper than Opus per token). 100 AI generation hard cap per month. Meter displayed in dashboard. Net margin at scale: ~$15–16/month.
- **Elite ($29.99/mo)**: 50 Opus generations/month. Beyond quota: auto-downgrades to Haiku. Overage billing: $0.10/generation via Stripe metered billing. 500 client soft cap.

---

## 03 — Complete Feature Set

### Core Management
* **Client Management**: Full CRUD, bulk CSV import, smart onboarding, goal/language-based auto-assignment.
* **Membership & Subscription**: Flexible durations, automated renewal invoices, GST-compliant invoice generation (18%), overdue tracking, trainer commissions.
* **Trainer System**: Role-based access, workload monitor (warns at 80% capacity), trainer performance score (retention 40%, progress 30%, response time 20%, logging 10%).

### AI Engine Features
* **Workout Plans**: Periodization-aware, specific splits, auto-deload, active recovery, full exercise cues, substitutes, and injury flags.
* **Nutrition Plans**: Mifflin-St Jeor BMR calculation + activity factor + goal adjustment. Indian food database included. Strict restriction compliance (veg, vegan, keto, diabetic, etc.). Supplement Stack Advisor.
* **Progress Intelligence**: Diagnostic sequence for adherence, weight stall detection, auto-adjusts plan intensity, at-risk alerts.
* **AI Client Chat (Elite)**: Claude Opus handles questions with full profile context (boundaries enforced).

### Business Intelligence (Elite)
* **Revenue Metrics**: Live MRR/ARR, churn rate, client LTV, revenue forecast (30/60/90 days).
* **Gym Operations**: Peak hour heatmap (QR check-in based), upgrade trigger alerts (flag gyms near limits).

### Engagement & Gamification
* **Retention Hooks**: Streak system, opt-in leaderboard, custom milestone rewards, encrypted before/after photo vault, weekly goal trajectory checkpoints.

### Communication & Indian Market Features
* **Comms**: WhatsApp notifications (India-primary), in-app chat (text, voice note, images, PDF, 60s video), broadcast messaging.
* **India First**: Razorpay integration (UPI, net banking, EMI), GST invoices, complete Hindi UI support, offline mode sync, Indian food database priority.

---

## 04 — Technical Architecture

### Multi-Tenant Data Model
* **Isolation Strategy**: PostgreSQL Row-level security (RLS) scoping queries to `gym_id`. JWT tokens carry user role, gym, and plan tier. Read/Write constraints explicitly prevent cross-gym data leakage.

### AI Integration Architecture (Model Routing)
* **Basic plan**: No AI calls (returns 403).
* **Pro plan**: `claude-haiku-4-5-20251001` (fast, cheap). 500,000 tokens (~100 plans).
* **Elite plan**: `claude-opus-4-5` (powerful). 200,000 tokens (~50 plans). Over quota downgrades to Haiku + metered overage.

### Build Priorities
1. Auth + multi-tenant setup (Base)
2. Client CRUD + membership tracking (Core Value)
3. Stripe + Razorpay billing (Revenue)
4. Basic dashboard (Validation)
5. Manual workout/diet builders (Non-AI fallback)
6. Claude Haiku integration - Pro (AI Layer)
7. Client mobile app - Flutter (UX)
8. WhatsApp notifications (Retention)
9. Claude Opus + AI chat - Elite (Premium)
10. Analytics, heatmap, white-label (Differentiation)

---

## 05 — Competitive Positioning & Moat

**The Market Gap**: Enterprise software (Mindbody, Perfect Gym, $300+) has no AI diet plans or India focus. Budget software (Gymdesk, PushPress) has no AI or trainer delegation.

**The GymOS Defensible Moat**:
Only GymOS simultaneously offers:
1. **AI-generated workout AND diet plans** (deep Indian food integrated).
2. **Flat pricing under $30/month** (not per-member, which punishes growth).
3. **Built for the Indian market** (UPI, GST, Hindi, Offline mode).

*Code and Documentation strictly adhere to the GymOS v2.0 Specifications and Master System Prompt.*
