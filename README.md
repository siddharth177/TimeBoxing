<div align="center">

<img src="screenshots/hero_banner.png" alt="TimeBox — Timebox your day, own your time" width="100%" />

<br />

# TimeBox

### *Timebox your day. Own your time.*

A mindful, AI-powered timeboxing app — bridging the gap between long-term ambition and daily
execution.

<br />

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Open%20App-4CAF50?style=for-the-badge&logo=google&logoColor=white)](https://siddharth177.github.io/TimeBoxing/)

<br />

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/AI-Gemini%202.0%20Flash-4285F4?style=flat-square&logo=google&logoColor=white)
![Groq](https://img.sheilds.io/badge/AI%20Fallback-Groq%20Llama%203.3-F55036?style=flat-square&logo=groq&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod%203-00BCD4?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?style=flat-square)

</div>

---

## The Problem

Most productivity apps are glorified to-do lists. They let you capture tasks endlessly but never
answer the one question that matters: *when, exactly, are you doing this?*

The deeper problem is a broken link between the goals people set and the days they actually live.
Someone sets a goal to get fit, get promoted, or ship a side project — but their daily schedule
looks nothing like that goal.

TimeBox is built on a single premise: **a goal without a time block is just a wish.**

---

## Product Vision

TimeBox connects three layers that most apps treat as completely separate products:

```
Long-range goals  ──▶  Weekly priorities & chores  ──▶  Today's schedule
  (1–5 years)              (this week's tasks)             (exact hours)
        ▲                                                       │
        └──────────────  Daily review & AI insights  ◀──────────┘
```

Goals decompose into tasks. Tasks anchor to time blocks. Daily review closes the loop with
structured reflection and AI-generated insight. Every feature exists to strengthen that chain —
nothing exists outside it.

---

## Key Product Decisions

### Timeboxing over task lists

Traditional to-do apps let tasks pile up infinitely. TimeBox forces every task to compete for a real
time slot. If it doesn't fit, it doesn't happen — which is honest. This creates natural
prioritisation pressure without requiring the user to manually rank everything.

### Chores first, priorities second

The day is gated: the priority backlog is locked until at least one chore has been scheduled. This
mirrors how high-performers actually operate — non-negotiable maintenance (exercise, admin,
routines) is handled first so deep work isn't crowded out by guilt later.

### Three-tier goal hierarchy

Most goal apps go one level deep (goal → task). TimeBox uses three tiers — long-term (1–5 years),
medium-term (quarterly), short-term (weekly) — because that is the minimum structure needed to make
an ambitious goal actionable without it feeling overwhelming. Completion cascades upward
automatically.

### AI as assistant, not author

Gemini can decompose a long-term goal into a full structured plan in seconds. But every suggestion
surfaces in an editable review step before anything is saved. The user approves, edits, or rejects.
This is a deliberate choice: AI that acts without consent erodes trust; AI that proposes and waits
builds it.

### Streaks for accountability, not gamification

The streak counter exists for one reason — it creates a mild daily commitment. Losing a 14-day
streak hurts just enough to motivate the review habit. It is not a leaderboard, not social, and not
visible to anyone else. Accountability without performance pressure.

### Warm design, not clinical

Most productivity tools use cold blues and dense tables — they feel like enterprise software.
TimeBox uses a warm, earthy palette (browns, greens, ambers) to signal that this is a personal tool,
not a corporate one. Calm focus beats anxious efficiency.

---

## Features

<br />

<table>
<tr>
<td width="58%" valign="top">

### 🗓️ Daily Timeboxing

An interactive daily schedule where tasks are dragged into real time slots. A week strip gives quick
day navigation, a live indicator marks the active block, and any unscheduled tasks from yesterday
surface automatically as carryovers.

*TimeBox forces every task to compete for real time — if it doesn't fit, it doesn't happen. That's
not a limitation, it's honest prioritisation.*

</td>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_timeboxing.png" width="210" alt="Timeboxing" />
</td>
</tr>
</table>

<br />

<table>
<tr>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_goals.png" width="210" alt="Goals" />
</td>
<td width="58%" valign="top">

### 🎯 Three-Tier Goal Hierarchy

Goals are structured across three horizons:

| Tier            | Horizon   | Example           |
|-----------------|-----------|-------------------|
| **Long-term**   | 1–5 years | *Top MBA program* |
| **Medium-term** | Quarterly | *Ace the GMAT*    |
| **Short-term**  | Weekly    | *2 mock tests*    |

When all short-term goals under a parent are complete, the parent closes automatically — momentum
compounds upward without any manual tracking.

</td>
</tr>
</table>

<br />

<table>
<tr>
<td width="58%" valign="top">

### ✨ AI Goal Planning

Describe a long-term goal and Gemini returns a full structured breakdown — medium-term milestones,
short-term checkpoints, and ready-to-schedule tasks. Every suggestion is editable before anything is
saved. The user always has the final word.

</td>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_ai_goal.png" width="210" alt="AI Goal Planning" />
</td>
</tr>
</table>

<br />

<table>
<tr>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_focus.png" width="210" alt="Focus Mode" />
</td>
<td width="58%" valign="top">

### 🔥 Focus Mode

A distraction-free, full-screen view of the active time block — task name, live progress bar, time
remaining, and the next upcoming block. No navigation chrome, no distractions. Designed to keep the
user in the session, not managing the app.

</td>
</tr>
</table>

<br />

<table>
<tr>
<td width="58%" valign="top">

### 📓 Daily Review & Reflection

An end-of-day flow: mark tasks complete or skipped, rate mood on a five-point scale, see the day's
completion rate. Streaks build a mild daily commitment — losing a 14-day streak hurts just enough to
motivate the habit. AI periodically analyses review history to surface personalised patterns and
insights.

</td>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_review.png" width="210" alt="Daily Review" />
</td>
</tr>
</table>

<br />

<table>
<tr>
<td width="42%" align="center" valign="top">
<img src="screenshots/screen_planner.png" width="210" alt="Planner" />
</td>
<td width="58%" valign="top">

### 📋 Prioritised Backlog

Tasks live in a backlog split into **chores** (recurring, non-negotiable) and **priorities** (
deep-work items). The priority list is hidden until a chore is scheduled — enforcing the discipline
of handling essentials before discretionary work, structurally rather than by willpower.

</td>
</tr>
</table>

<br />

### 🔔 Smart Notifications

Timezone-aware local notifications remind you when a time block is starting, and send a
streak-preservation nudge if the daily review hasn't been completed. Fire reliably even when the app
is backgrounded or closed.

### 📅 Calendar Sync

Time blocks are written directly to the device's native calendar - Google Calendar on Android,
Apple Calendar / iCloud on iOS, or any Exchange-synced calendar the device has access to. No
third-party OAuth required: the app writes through the platform's calendar API, and the device
handles
cloud sync to whichever provider the user has configured.

---

## Technical Architecture

Built as a solo full-stack mobile product — from Figma to Firebase.

<br />

**Flutter + Dart 3** — A single codebase compiles natively to both iOS and Android with no
JavaScript bridge and no platform-specific UI compromises. Dart's strong typing and null safety
catch entire categories of runtime errors at compile time. Material 3's component system let the
warm, earthy design language ship at speed without sacrificing fidelity.

**Riverpod 3 (`Notifier` / `AsyncNotifier`)** — Compile-safe, dependency-injected reactive state
with zero global singletons. Providers are scoped to the widget tree, auto-disposed when unused, and
trivially testable. The codebase runs entirely on the modern `Notifier` pattern — no legacy
`StateNotifier` or `StateProvider` anywhere.

**Firebase Firestore** — Live snapshot streams power every screen. Goals, tasks, time blocks, and
review entries update in real time across devices with no polling. Offline persistence keeps the app
fully functional without a connection; writes queue and sync automatically on reconnect. All
security rules are user-scoped — no cross-user data access is possible at the rules level.

**Firebase Auth** — Email/password, Google, and Apple sign-in via `signInWithProvider`. No backend
middleware required. Firebase App Check (Play Integrity on Android, App Attest on iOS) blocks API
requests from non-genuine clients.

**Firebase AI Logic — Gemini 2.0 Flash** — Goal decomposition and review analysis run through
Firebase's AI proxy, authenticated with Firebase credentials. No separate API key management, no
custom backend, no cold-start penalty. The model is invoked only on explicit user action — no
background AI processing. **Groq (Llama 3.3 70B)** acts as a hot-standby fallback: if the Firebase
AI call fails, the request is retried against the Groq API transparently, keeping AI features
available during Firebase outages.

**go_router** — Declarative URL-based routing with authentication guards. Clean deep-link support
without imperative `Navigator` calls scattered through the tree.

**flutter_local_notifications** — Block-start reminders and streak nudges scheduled as exact alarms
with full timezone awareness. Fire reliably when the app is backgrounded or killed, delegated to the
platform's native alarm infrastructure.

<br />

| Layer             | Technology                                |
|-------------------|-------------------------------------------|
| **UI**            | Flutter 3 + Dart 3.12 + Material 3        |
| **State**         | Riverpod 3 — `Notifier` / `AsyncNotifier` |
| **Navigation**    | go_router                                 |
| **Database**      | Firebase Firestore                        |
| **Auth**          | Firebase Auth + App Check                 |
| **AI**            | Firebase AI Logic (Gemini 2.0 Flash)      |
| **Notifications** | flutter_local_notifications v22           |
| **Calendar**      | device_calendar (Android + iOS native)    |
| **AI Fallback**   | Groq - Llama 3.3 70b Versatile            |

---

<div align="center">

<img src="screenshots/footer_banner.png" alt="TimeBox" width="60%" />

*Built independently — from Figma to Firebase.*

</div>
