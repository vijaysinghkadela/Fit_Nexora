# FitNexora AI Agent — Complete Integration Guide
### Claude Code + Supabase + Anthropic API

> **Document Version:** 1.0  
> **Audience:** Technical founders, backend developers integrating the FitNexora AI Agent  
> **Stack:** Next.js · Supabase · Anthropic Claude API · Claude Code  
> **Plans Affected:** Elite Plan (partial) · Master Plan (full access)

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Prerequisites & Setup](#2-prerequisites--setup)
3. [Supabase Schema Design](#3-supabase-schema-design)
4. [Claude Code — AI Agent Structure](#4-claude-code--ai-agent-structure)
5. [Body Type Analysis Module](#5-body-type-analysis-module)
6. [Workout Plan Generator](#6-workout-plan-generator)
7. [Diet Plan Generator](#7-diet-plan-generator)
8. [Monthly Report Engine](#8-monthly-report-engine)
9. [API Routes (Next.js)](#9-api-routes-nextjs)
10. [Workflow Orchestration](#10-workflow-orchestration)
11. [PDF Report Generation](#11-pdf-report-generation)
12. [Plan-Gating (Elite vs Master)](#12-plan-gating-elite-vs-master)
13. [Security & Privacy](#13-security--privacy)
14. [Testing & Deployment](#14-testing--deployment)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Overview & Architecture

The FitNexora AI Agent is a server-side intelligence layer that:

1. **Pulls** a gym member's data from Supabase
2. **Analyses** body metrics, visit history, and fitness goals
3. **Generates** personalised workout plans, diet plans, and tips via Claude API
4. **Compiles** a structured monthly report and renders it as a downloadable PDF
5. **Stores** results back to Supabase for the gym owner's dashboard

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GYM OWNER DASHBOARD                  │
│              (Next.js Frontend — FitNexora)             │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP
┌────────────────────────▼────────────────────────────────┐
│              NEXT.JS API ROUTES (Server-Side)           │
│   /api/ai/analyse  /api/ai/workout  /api/ai/diet        │
│   /api/ai/report                                        │
└──────┬─────────────────────────────────────┬────────────┘
       │                                     │
       ▼                                     ▼
┌──────────────┐                    ┌────────────────────┐
│  SUPABASE    │                    │  ANTHROPIC CLAUDE  │
│  PostgreSQL  │ ◄── data in/out ──►│  API (claude-      │
│  (RLS-locked │                    │  sonnet-4)         │
│  per gym)    │                    └────────────────────┘
└──────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│  AI REPORT ENGINE (PDF Generation)      │
│  Rendered server-side → Supabase Storage │
└──────────────────────────────────────────┘
```

### Agent Workflow (Monthly Report Trigger)

```
Cron Job (1st of month)
  → Pull all members from Supabase
  → For each member:
      1. Fetch body metrics + visit logs
      2. Send to Claude → get body analysis
      3. Send profile to Claude → get workout plan
      4. Send profile to Claude → get diet plan
      5. Compile all outputs into report struct
      6. Generate PDF report
      7. Upload PDF to Supabase Storage
      8. Notify gym owner via in-app notification
```

---

## 2. Prerequisites & Setup

### 2.1 Environment Variables

Create a `.env.local` file at the root of your Next.js project:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://yabnagrxqamiivictoho.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here   # Server-side only, never expose to client

# Anthropic
ANTHROPIC_API_KEY=your_anthropic_api_key_here          # Server-side only, never expose to client

# App
NEXTAUTH_SECRET=your_nextauth_secret
NEXT_PUBLIC_APP_URL=https://app.fitnexora.ai
```

> **CRITICAL:** `SUPABASE_SERVICE_ROLE_KEY` and `ANTHROPIC_API_KEY` must **never** be prefixed with `NEXT_PUBLIC_`. They must only ever be accessed from server-side routes or API handlers.

### 2.2 Install Dependencies

```bash
npm install @anthropic-ai/sdk @supabase/supabase-js @supabase/ssr
npm install puppeteer     # for PDF generation (server-side)
npm install date-fns      # for date calculations
npm install zod           # for schema validation
```

### 2.3 Claude Code Setup

Install Claude Code globally:

```bash
npm install -g @anthropic-ai/claude-code
```

Configure Claude Code with your API key:

```bash
claude config set api-key $ANTHROPIC_API_KEY
```

Start a Claude Code session for AI agent development:

```bash
claude code
```

Use Claude Code to scaffold your agent:

```
> Create a TypeScript module that connects to Supabase, fetches a member's 
  fitness profile, sends it to the Anthropic API, and returns a structured 
  JSON with workout plan and diet plan recommendations.
```

---

## 3. Supabase Schema Design

Run the following SQL in your Supabase SQL Editor to create the AI agent's data tables.

### 3.1 Member Fitness Profile Table

```sql
-- Member body metrics and fitness goals
CREATE TABLE member_fitness_profiles (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,

  -- Body metrics
  height_cm       NUMERIC(5,1),
  weight_kg       NUMERIC(5,1),
  body_fat_pct    NUMERIC(4,1),
  muscle_mass_kg  NUMERIC(5,1),
  bmi             NUMERIC(4,1),
  age             INTEGER,
  gender          TEXT CHECK (gender IN ('male', 'female', 'other')),

  -- Fitness context
  fitness_level   TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  primary_goal    TEXT CHECK (primary_goal IN (
                    'weight_loss', 'muscle_gain', 'endurance',
                    'flexibility', 'general_fitness', 'sports_performance'
                  )),
  secondary_goal  TEXT,
  injuries        TEXT[],                  -- e.g. ARRAY['lower_back', 'left_knee']
  available_days  INTEGER DEFAULT 5,       -- days per week available to train

  -- Diet context
  diet_type       TEXT CHECK (diet_type IN (
                    'vegetarian', 'vegan', 'non_vegetarian',
                    'eggetarian', 'keto', 'paleo'
                  )),
  food_allergies  TEXT[],
  calorie_target  INTEGER,

  -- Timestamps
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: gym can only see its own members
ALTER TABLE member_fitness_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gym_isolation" ON member_fitness_profiles
  USING (gym_id = (SELECT gym_id FROM user_gym_map WHERE user_id = auth.uid()));
```

### 3.2 AI-Generated Plans Table

```sql
-- Stores AI-generated workout and diet plans
CREATE TABLE ai_generated_plans (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,

  plan_month      DATE NOT NULL,           -- First day of the month this plan covers
  plan_type       TEXT NOT NULL CHECK (plan_type IN ('workout', 'diet', 'combined')),

  -- AI outputs (stored as structured JSON)
  body_analysis   JSONB,
  workout_plan    JSONB,
  diet_plan       JSONB,
  tips            TEXT[],

  -- Generation metadata
  model_used      TEXT DEFAULT 'claude-sonnet-4-20250514',
  tokens_used     INTEGER,
  generation_ms   INTEGER,

  -- Report PDF
  report_pdf_url  TEXT,                    -- Supabase Storage URL

  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE ai_generated_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gym_isolation" ON ai_generated_plans
  USING (gym_id = (SELECT gym_id FROM user_gym_map WHERE user_id = auth.uid()));
```

### 3.3 Visit Logs View (for AI context)

```sql
-- Aggregated visit summary used by AI agent
CREATE OR REPLACE VIEW member_visit_summary AS
SELECT
  member_id,
  COUNT(*) AS total_visits,
  COUNT(*) FILTER (WHERE visited_at >= NOW() - INTERVAL '30 days') AS visits_last_30_days,
  COUNT(*) FILTER (WHERE visited_at >= NOW() - INTERVAL '7 days')  AS visits_last_7_days,
  MAX(visited_at) AS last_visit,
  ROUND(AVG(EXTRACT(EPOCH FROM (checkout_time - checkin_time))/3600)::numeric, 1) AS avg_session_hrs
FROM attendance_logs
GROUP BY member_id;
```

---

## 4. Claude Code — AI Agent Structure

### 4.1 File Structure

```
src/
├── lib/
│   ├── supabase/
│   │   ├── server.ts          # Supabase server client (service role)
│   │   └── types.ts           # Generated Supabase types
│   └── ai/
│       ├── agent.ts           # Main AI agent orchestrator
│       ├── prompts/
│       │   ├── bodyAnalysis.ts
│       │   ├── workoutPlan.ts
│       │   ├── dietPlan.ts
│       │   └── monthlyReport.ts
│       ├── schemas/
│       │   └── planSchemas.ts # Zod schemas for AI output validation
│       └── reportPdf.ts       # PDF generation from AI output
├── app/
│   └── api/
│       └── ai/
│           ├── analyse/route.ts
│           ├── workout/route.ts
│           ├── diet/route.ts
│           └── report/route.ts
```

### 4.2 Supabase Server Client

```typescript
// src/lib/supabase/server.ts
import { createClient } from '@supabase/supabase-js'

// Service role client — server-side only
export function createServiceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,  // Never expose this to client
    { auth: { autoRefreshToken: false, persistSession: false } }
  )
}
```

---

## 5. Body Type Analysis Module

### 5.1 Prompt Engineering

```typescript
// src/lib/ai/prompts/bodyAnalysis.ts

export function buildBodyAnalysisPrompt(profile: MemberFitnessProfile): string {
  return `
You are an expert sports scientist and certified personal trainer.
Analyse the following gym member's body metrics and return ONLY valid JSON.
Do not include any explanation, markdown, or text outside the JSON object.

MEMBER PROFILE:
- Age: ${profile.age} years
- Gender: ${profile.gender}
- Height: ${profile.height_cm} cm
- Weight: ${profile.weight_kg} kg
- BMI: ${profile.bmi}
- Body Fat %: ${profile.body_fat_pct ?? 'Not recorded'}
- Fitness Level: ${profile.fitness_level}
- Primary Goal: ${profile.primary_goal}
- Injuries/Limitations: ${profile.injuries?.join(', ') || 'None'}

Respond with a JSON object matching EXACTLY this structure:
{
  "somatotype": "ectomorph | mesomorph | endomorph | ecto-mesomorph | endo-mesomorph",
  "somatotype_explanation": "2-3 sentence explanation of what this means for this person",
  "bmi_category": "underweight | normal | overweight | obese",
  "bmi_interpretation": "1-2 sentences interpreting BMI in context of their goals",
  "fitness_assessment": "Brief assessment of their current fitness level",
  "key_strengths": ["strength 1", "strength 2", "strength 3"],
  "areas_to_improve": ["area 1", "area 2", "area 3"],
  "recommended_focus": "muscle_gain | fat_loss | endurance | strength | flexibility | balanced",
  "risk_flags": ["any injury risks or health flags to communicate to trainer"]
}
`
}
```

### 5.2 Body Analysis Function

```typescript
// src/lib/ai/agent.ts
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,  // Server-side only
})

export async function analyseBodyType(profile: MemberFitnessProfile) {
  const startTime = Date.now()

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: buildBodyAnalysisPrompt(profile),
      },
    ],
  })

  const rawText = response.content[0].type === 'text'
    ? response.content[0].text
    : ''

  // Strip markdown fences if Claude adds them despite instructions
  const cleaned = rawText
    .replace(/```json\n?/g, '')
    .replace(/```\n?/g, '')
    .trim()

  const parsed = JSON.parse(cleaned)

  return {
    analysis: parsed,
    tokensUsed: response.usage.input_tokens + response.usage.output_tokens,
    generationMs: Date.now() - startTime,
  }
}
```

---

## 6. Workout Plan Generator

### 6.1 Workout Plan Prompt

```typescript
// src/lib/ai/prompts/workoutPlan.ts

export function buildWorkoutPrompt(
  profile: MemberFitnessProfile,
  bodyAnalysis: BodyAnalysisResult,
  visitStats: MemberVisitSummary
): string {
  return `
You are a certified strength and conditioning coach creating a monthly workout plan.
Return ONLY valid JSON. No markdown, no explanations outside the JSON.

MEMBER DATA:
- Somatotype: ${bodyAnalysis.somatotype}
- Primary Goal: ${profile.primary_goal}
- Fitness Level: ${profile.fitness_level}
- Available Training Days/Week: ${profile.available_days}
- Injuries: ${profile.injuries?.join(', ') || 'None'}
- Avg Gym Visit Duration: ${visitStats.avg_session_hrs} hours
- Visits last 30 days: ${visitStats.visits_last_30_days}
- Recommended Focus: ${bodyAnalysis.recommended_focus}

Create a 4-week progressive workout plan. Each week should be slightly harder than the last.

JSON structure:
{
  "plan_name": "e.g. 4-Week Fat Burn Accelerator",
  "weekly_structure": "e.g. 5 days on, 2 days rest",
  "progression_logic": "brief explanation of how intensity increases each week",
  "weeks": [
    {
      "week": 1,
      "theme": "e.g. Foundation",
      "intensity": "low | moderate | high",
      "days": [
        {
          "day": "Monday",
          "focus": "e.g. Upper Body Push",
          "exercises": [
            {
              "name": "Bench Press",
              "sets": 3,
              "reps": "10-12",
              "rest_seconds": 60,
              "notes": "Keep elbows at 45 degrees"
            }
          ],
          "cardio": "e.g. 20 min moderate treadmill",
          "estimated_duration_mins": 60
        }
      ]
    }
  ],
  "warm_up_protocol": "General 5-minute warm-up description",
  "cool_down_protocol": "General cool-down and stretching description",
  "trainer_tips": ["tip 1", "tip 2", "tip 3"]
}
`
}
```

---

## 7. Diet Plan Generator

### 7.1 Diet Plan Prompt

```typescript
// src/lib/ai/prompts/dietPlan.ts

export function buildDietPrompt(
  profile: MemberFitnessProfile,
  bodyAnalysis: BodyAnalysisResult
): string {
  // Calculate estimated TDEE (Total Daily Energy Expenditure)
  const bmr = profile.gender === 'male'
    ? 88.36 + (13.4 * profile.weight_kg) + (4.8 * profile.height_cm) - (5.7 * profile.age)
    : 447.6 + (9.2 * profile.weight_kg) + (3.1 * profile.height_cm) - (4.3 * profile.age)

  const activityMultiplier = profile.available_days >= 5 ? 1.55 : 1.375
  const tdee = Math.round(bmr * activityMultiplier)

  return `
You are a certified sports nutritionist. Return ONLY valid JSON. No text outside the JSON.

MEMBER PROFILE:
- Age: ${profile.age}, Gender: ${profile.gender}
- Weight: ${profile.weight_kg}kg, Height: ${profile.height_cm}cm
- Primary Goal: ${profile.primary_goal}
- Diet Type: ${profile.diet_type}
- Food Allergies: ${profile.food_allergies?.join(', ') || 'None'}
- Estimated TDEE: ${tdee} calories/day
- Calorie Target Override: ${profile.calorie_target ?? 'Use TDEE-based calculation'}
- Training Days/Week: ${profile.available_days}

Create a practical, culturally appropriate (Indian context) diet plan.

JSON structure:
{
  "calorie_target": 2200,
  "protein_g": 160,
  "carbs_g": 250,
  "fats_g": 70,
  "meal_timing": "brief guidance on when to eat relative to training",
  "daily_template": {
    "early_morning": {
      "time": "6:00 AM",
      "items": [
        { "food": "Warm water with lemon", "quantity": "1 glass", "calories": 5 }
      ]
    },
    "breakfast": { "time": "7:30 AM", "items": [] },
    "mid_morning": { "time": "10:30 AM", "items": [] },
    "lunch": { "time": "1:00 PM", "items": [] },
    "pre_workout": { "time": "4:30 PM", "items": [] },
    "post_workout": { "time": "7:00 PM", "items": [] },
    "dinner": { "time": "8:30 PM", "items": [] }
  },
  "hydration_target_litres": 3.5,
  "supplements": [
    { "name": "Whey Protein", "timing": "Post-workout", "dose": "25g", "optional": false }
  ],
  "foods_to_avoid": ["specific foods to avoid based on goals"],
  "nutritionist_tips": ["tip 1", "tip 2", "tip 3"]
}
`
}
```

---

## 8. Monthly Report Engine

### 8.1 Report Prompt

```typescript
// src/lib/ai/prompts/monthlyReport.ts

export function buildMonthlyReportPrompt(
  profile: MemberFitnessProfile,
  bodyAnalysis: BodyAnalysisResult,
  workoutPlan: WorkoutPlan,
  dietPlan: DietPlan,
  visitStats: MemberVisitSummary
): string {
  return `
You are a senior fitness coach writing a monthly progress report for a gym member.
Write in an encouraging, professional, and direct tone.
Return ONLY valid JSON. No markdown or text outside the JSON.

CONTEXT:
- Member visits this month: ${visitStats.visits_last_30_days}
- Average session duration: ${visitStats.avg_session_hrs} hours
- Body type: ${bodyAnalysis.somatotype}
- Primary goal: ${profile.primary_goal}
- Fitness level: ${profile.fitness_level}

JSON structure:
{
  "report_month": "${new Date().toLocaleDateString('en-IN', {month: 'long', year: 'numeric'})}",
  "executive_summary": "3-4 sentence overview of the member's month",
  "attendance_analysis": {
    "verdict": "excellent | good | fair | poor",
    "comment": "Specific comment on their attendance this month"
  },
  "progress_assessment": {
    "overall_rating": 1-10,
    "positive_indicators": ["point 1", "point 2"],
    "areas_needing_attention": ["area 1", "area 2"]
  },
  "next_month_focus": [
    { "priority": 1, "focus": "Title", "action": "Specific action step" },
    { "priority": 2, "focus": "Title", "action": "Specific action step" },
    { "priority": 3, "focus": "Title", "action": "Specific action step" }
  ],
  "motivational_message": "Personal, specific motivational closing message",
  "trainer_recommendations": ["recommendation 1", "recommendation 2"]
}
`
}
```

### 8.2 Main Orchestrator

```typescript
// src/lib/ai/agent.ts  (continued)

export async function generateMemberReport(memberId: string, gymId: string) {
  const supabase = createServiceClient()

  // 1. Fetch fitness profile
  const { data: profile } = await supabase
    .from('member_fitness_profiles')
    .select('*')
    .eq('member_id', memberId)
    .single()

  if (!profile) throw new Error(`No fitness profile found for member ${memberId}`)

  // 2. Fetch visit statistics
  const { data: visitStats } = await supabase
    .from('member_visit_summary')
    .select('*')
    .eq('member_id', memberId)
    .single()

  // 3. Run AI analysis pipeline (parallel where possible)
  const { analysis: bodyAnalysis, tokensUsed: t1 } = await analyseBodyType(profile)

  const [workoutResult, dietResult] = await Promise.all([
    generateWorkoutPlan(profile, bodyAnalysis, visitStats),
    generateDietPlan(profile, bodyAnalysis),
  ])

  const { report, tokensUsed: t3 } = await generateMonthlyReport(
    profile, bodyAnalysis, workoutResult.plan, dietResult.plan, visitStats
  )

  // 4. Compile full report object
  const fullReport = {
    member_id: memberId,
    gym_id: gymId,
    plan_month: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    plan_type: 'combined',
    body_analysis: bodyAnalysis,
    workout_plan: workoutResult.plan,
    diet_plan: dietResult.plan,
    tips: report.trainer_recommendations,
    model_used: 'claude-sonnet-4-20250514',
    tokens_used: t1 + workoutResult.tokensUsed + dietResult.tokensUsed + t3,
  }

  // 5. Save to Supabase
  const { data: savedReport } = await supabase
    .from('ai_generated_plans')
    .insert(fullReport)
    .select()
    .single()

  // 6. Generate PDF and upload
  const pdfBuffer = await generateReportPDF(profile, fullReport, report)
  const pdfPath = `reports/${gymId}/${memberId}/${savedReport.id}.pdf`

  await supabase.storage
    .from('member-reports')
    .upload(pdfPath, pdfBuffer, { contentType: 'application/pdf', upsert: true })

  const { data: { publicUrl } } = supabase.storage
    .from('member-reports')
    .getPublicUrl(pdfPath)

  // 7. Update record with PDF URL
  await supabase
    .from('ai_generated_plans')
    .update({ report_pdf_url: publicUrl })
    .eq('id', savedReport.id)

  // 8. Create in-app notification for gym owner
  await supabase.from('notifications').insert({
    gym_id: gymId,
    type: 'ai_report_ready',
    title: 'Monthly AI Report Ready',
    message: `${profile.member_id}'s monthly report has been generated.`,
    action_url: `/reports/${savedReport.id}`,
  })

  return { reportId: savedReport.id, pdfUrl: publicUrl }
}
```

---

## 9. API Routes (Next.js)

### 9.1 Report Generation Endpoint

```typescript
// src/app/api/ai/report/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'
import { generateMemberReport } from '@/lib/ai/agent'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { memberId, gymId } = body

    if (!memberId || !gymId) {
      return NextResponse.json(
        { error: 'memberId and gymId are required' },
        { status: 400 }
      )
    }

    // Verify gym plan — only Master plan gets AI reports
    const supabase = createServiceClient()
    const { data: gym } = await supabase
      .from('gyms')
      .select('plan_type')
      .eq('id', gymId)
      .single()

    if (gym?.plan_type !== 'master') {
      return NextResponse.json(
        { error: 'AI Reports require the Master Plan. Please upgrade.' },
        { status: 403 }
      )
    }

    // Generate report (this takes 10-30 seconds)
    const result = await generateMemberReport(memberId, gymId)

    return NextResponse.json({
      success: true,
      reportId: result.reportId,
      pdfUrl: result.pdfUrl,
    })

  } catch (error) {
    console.error('[AI Report Error]', error)
    return NextResponse.json(
      { error: 'Failed to generate report. Please try again.' },
      { status: 500 }
    )
  }
}
```

### 9.2 Bulk Report Trigger (Cron)

```typescript
// src/app/api/ai/cron/monthly-reports/route.ts
// Called by Vercel Cron or external cron service on 1st of each month

import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'
import { generateMemberReport } from '@/lib/ai/agent'

export async function GET(request: NextRequest) {
  // Verify cron secret to prevent unauthorized calls
  const authHeader = request.headers.get('authorization')
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const supabase = createServiceClient()

  // Get all Master plan gyms
  const { data: masterGyms } = await supabase
    .from('gyms')
    .select('id')
    .eq('plan_type', 'master')

  const results = []

  for (const gym of masterGyms ?? []) {
    // Get all active members
    const { data: members } = await supabase
      .from('members')
      .select('id')
      .eq('gym_id', gym.id)
      .eq('status', 'active')

    for (const member of members ?? []) {
      try {
        const result = await generateMemberReport(member.id, gym.id)
        results.push({ memberId: member.id, status: 'success', ...result })
      } catch (err) {
        results.push({ memberId: member.id, status: 'failed', error: String(err) })
      }
    }
  }

  return NextResponse.json({ processed: results.length, results })
}
```

---

## 10. Workflow Orchestration

### 10.1 Vercel Cron Configuration

```json
// vercel.json
{
  "crons": [
    {
      "path": "/api/ai/cron/monthly-reports",
      "schedule": "0 6 1 * *"
    }
  ]
}
```

> This triggers the monthly report generation on the 1st of every month at 6:00 AM UTC.

### 10.2 Manual Trigger from Dashboard

```typescript
// In your React component (client-side)
async function triggerMemberReport(memberId: string) {
  setLoading(true)
  try {
    const response = await fetch('/api/ai/report', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ memberId, gymId: currentGymId }),
    })

    if (!response.ok) {
      const error = await response.json()
      // Handle plan-gating error
      if (response.status === 403) {
        showUpgradePrompt()
        return
      }
      throw new Error(error.message)
    }

    const { pdfUrl } = await response.json()
    window.open(pdfUrl, '_blank')  // Open PDF in new tab
  } catch (err) {
    showErrorToast('Failed to generate report')
  } finally {
    setLoading(false)
  }
}
```

---

## 11. PDF Report Generation

```typescript
// src/lib/ai/reportPdf.ts
// Uses puppeteer to render an HTML template and export as PDF

import puppeteer from 'puppeteer'

export async function generateReportPDF(
  profile: MemberFitnessProfile,
  fullReport: AiGeneratedPlan,
  monthlyReport: MonthlyReport
): Promise<Buffer> {
  const browser = await puppeteer.launch({ args: ['--no-sandbox'] })
  const page = await browser.newPage()

  const html = buildReportHTML(profile, fullReport, monthlyReport)
  await page.setContent(html, { waitUntil: 'networkidle0' })

  const pdf = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: { top: '20mm', bottom: '20mm', left: '15mm', right: '15mm' },
  })

  await browser.close()
  return pdf as Buffer
}

function buildReportHTML(profile: any, report: any, monthly: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; color: #1C1C1C; }
    .header { background: #0D0D0D; color: white; padding: 24px 32px; }
    .header h1 { color: #FF6B00; font-size: 28px; }
    .header p { color: #CCC; font-size: 13px; margin-top: 4px; }
    .section { padding: 24px 32px; border-bottom: 1px solid #EEE; }
    .section h2 { color: #FF6B00; font-size: 16px; margin-bottom: 12px; }
    .kpi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
    .kpi-card { background: #F5F5F5; border: 1px solid #FF6B00; padding: 16px;
                border-radius: 6px; text-align: center; }
    .kpi-card .value { font-size: 28px; font-weight: 700; color: #FF6B00; }
    .kpi-card .label { font-size: 11px; color: #666; margin-top: 4px; }
    .tip { padding: 8px 12px; background: #FFF3E8; border-left: 3px solid #FF6B00;
           margin: 6px 0; font-size: 12px; }
    .footer { background: #0D0D0D; color: #888; padding: 16px 32px;
              font-size: 10px; text-align: center; }
  </style>
</head>
<body>
  <div class="header">
    <h1>FitNexora Monthly Report</h1>
    <p>${monthly.report_month} &nbsp;|&nbsp; Member ID: ${profile.member_id}</p>
  </div>

  <div class="section">
    <h2>Executive Summary</h2>
    <p>${monthly.executive_summary}</p>
  </div>

  <div class="section">
    <h2>Body Analysis</h2>
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="value">${report.body_analysis.somatotype}</div>
        <div class="label">Body Type</div>
      </div>
      <div class="kpi-card">
        <div class="value">${report.body_analysis.bmi_category}</div>
        <div class="label">BMI Category</div>
      </div>
      <div class="kpi-card">
        <div class="value">${report.body_analysis.recommended_focus.replace('_', ' ')}</div>
        <div class="label">Recommended Focus</div>
      </div>
    </div>
    <p style="margin-top:12px; font-size:12px">${report.body_analysis.somatotype_explanation}</p>
  </div>

  <div class="section">
    <h2>Monthly Progress Assessment</h2>
    <p><strong>Overall Rating:</strong> ${monthly.progress_assessment.overall_rating}/10</p>
    <p><strong>Attendance:</strong> ${monthly.attendance_analysis.verdict.toUpperCase()} — ${monthly.attendance_analysis.comment}</p>
  </div>

  <div class="section">
    <h2>Next Month Priorities</h2>
    ${monthly.next_month_focus.map((f: any) => `
      <div class="tip"><strong>${f.priority}. ${f.focus}:</strong> ${f.action}</div>
    `).join('')}
  </div>

  <div class="section" style="background:#FFF3E8">
    <h2>Coach's Message</h2>
    <p style="font-style:italic; font-size:13px">${monthly.motivational_message}</p>
  </div>

  <div class="footer">
    FitNexora AI Report &nbsp;|&nbsp; Confidential &nbsp;|&nbsp; Generated by FitNexora GymOS AI
  </div>
</body>
</html>
  `
}
```

---

## 12. Plan-Gating (Elite vs Master)

### Feature Access Matrix

| Feature                    | Elite Plan | Master Plan |
|----------------------------|:----------:|:-----------:|
| Body Type Analysis         | —          | ✅           |
| Workout Plan Generation    | —          | ✅           |
| Diet Plan Generation       | —          | ✅           |
| Monthly AI Reports (PDF)   | —          | ✅           |
| Manual Report Trigger      | —          | ✅           |
| Automatic Monthly Reports  | —          | ✅           |

### Middleware Check

```typescript
// src/lib/ai/planGuard.ts
import { createServiceClient } from '@/lib/supabase/server'

export async function requireMasterPlan(gymId: string): Promise<void> {
  const supabase = createServiceClient()
  const { data: gym } = await supabase
    .from('gyms')
    .select('plan_type, plan_expires_at')
    .eq('id', gymId)
    .single()

  if (!gym || gym.plan_type !== 'master') {
    throw new Error('PLAN_GATE: AI features require the Master Plan')
  }

  if (new Date(gym.plan_expires_at) < new Date()) {
    throw new Error('PLAN_GATE: Your Master Plan subscription has expired')
  }
}
```

---

## 13. Security & Privacy

### Critical Rules — Never Break These

1. **`ANTHROPIC_API_KEY` must NEVER appear in client-side code.** All Claude API calls must be made from server-side API routes only.

2. **`SUPABASE_SERVICE_ROLE_KEY` must NEVER be sent to the browser.** Use it only in API routes with the `createServiceClient()` pattern above.

3. **PII anonymisation before AI calls.** Strip member names, phone numbers, and emails from the prompt. Use member IDs only.

4. **Row-Level Security on every table.** Every table that holds member data must have RLS enabled with gym-isolation policies.

5. **Audit log AI usage.** Every call to the Claude API must log the model used, tokens consumed, and the gym + member IDs to a server-side audit table.

6. **Rate-limit report generation.** A gym should not be able to generate more than 1 report per member per day to prevent API abuse.

```typescript
// Rate limit check before AI call
const { count } = await supabase
  .from('ai_generated_plans')
  .select('*', { count: 'exact', head: true })
  .eq('member_id', memberId)
  .gte('created_at', new Date(Date.now() - 86400000).toISOString())

if ((count ?? 0) >= 1) {
  throw new Error('RATE_LIMIT: Report already generated for this member today')
}
```

---

## 14. Testing & Deployment

### 14.1 Local Testing

```bash
# Test body analysis with a sample profile
curl -X POST http://localhost:3000/api/ai/analyse \
  -H "Content-Type: application/json" \
  -d '{
    "memberId": "test-member-uuid",
    "gymId": "test-gym-uuid"
  }'
```

### 14.2 Using Claude Code for Development

```bash
# Open Claude Code in your project root
claude code

# Ask Claude Code to:
# 1. Write tests for the body analysis function
> Write Jest unit tests for the analyseBodyType function in src/lib/ai/agent.ts

# 2. Debug a failing prompt
> The workout plan prompt is returning invalid JSON for members with no injuries. 
  Fix the buildWorkoutPrompt function to handle null injuries gracefully.

# 3. Optimise token usage
> Review all prompts in src/lib/ai/prompts/ and reduce token usage without 
  sacrificing output quality.
```

### 14.3 Deployment Checklist

```
□ All environment variables set in Vercel project settings
□ ANTHROPIC_API_KEY and SUPABASE_SERVICE_ROLE_KEY NOT prefixed with NEXT_PUBLIC_
□ Supabase RLS policies enabled on all AI-related tables
□ Vercel cron job configured for monthly report trigger
□ CRON_SECRET set and matched in vercel.json and Supabase
□ member-reports Supabase Storage bucket created with correct access policies
□ Puppeteer configured for Vercel serverless (use @sparticuz/chromium for lambda)
□ Error monitoring (Sentry or similar) configured on AI API routes
□ Rate limiting tested for report generation endpoints
```

---

## 15. Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `JSON.parse` error on Claude response | Claude added markdown fences | Strip ` ```json ` before parsing |
| Report generation times out | Puppeteer is slow on cold starts | Move PDF generation to a background job queue |
| `PLAN_GATE` error on Master plan gym | Plan type stored differently in DB | Check exact value in `gyms.plan_type` column |
| Supabase RLS blocks service client | Wrong client used | Use `createServiceClient()` (service role) not the anon client |
| Claude returns truncated JSON | `max_tokens` too low | Increase to 2048 for workout plans, 4096 for full reports |
| API key exposed in browser console | Used `NEXT_PUBLIC_` prefix | Remove prefix and move call to API route |

---

## Summary

You now have a complete blueprint to build the FitNexora AI Agent:

1. **Supabase schema** — tables for fitness profiles, AI plans, and visit summaries
2. **Claude API integration** — four specialised prompts for body analysis, workout, diet, and monthly reporting
3. **Next.js API routes** — secure server-side endpoints with plan gating
4. **PDF generation** — Puppeteer-based HTML-to-PDF rendering
5. **Cron automation** — monthly report trigger via Vercel Cron
6. **Security** — RLS, rate limiting, server-side-only API keys

**Recommended development order:**
1. Set up Supabase schema → 2. Test body analysis API route → 3. Add workout plan → 4. Add diet plan → 5. Build PDF report → 6. Wire up cron → 7. Add plan gating → 8. Deploy to production

---

*FitNexora Technologies Pvt. Ltd. — Internal Technical Documentation*  
*© 2025–2026 All rights reserved*
