# GoalForge — Complete Web Product Specification & Visual Audit (WEB_ANALYSIS.md)

This document is the authoritative product specification and visual audit of the **GoalForge** web application ([https://goal-forge-two.vercel.app/](https://goal-forge-two.vercel.app/)), captured directly via interactive browser exploration.

---

## 1. Executive Summary & Design System Tokens

GoalForge is a dark-themed, glassmorphic productivity application designed with a dark space-black background (`#0B0B14`), deep navy surface cards (`#161726`), dark input containers (`#121321`), and glowing indigo primary accents (`#6366F1` / `#3B75FF`).

### 1.1 Visual Color Tokens & Glassmorphic Palette

| Token Name | Hex / RGBA Value | Purpose & Usage |
| :--- | :--- | :--- |
| **App Canvas** | `#0B0B14` | Deep space black root page background |
| **Card Surface** | `#161726` | Deep navy glass card surface |
| **Input Background** | `#121321` | Inset dark container for form controls & inputs |
| **Primary Accent** | `#6366F1` / `#3B75FF` | Vibrant indigo for active tabs, CTAs, focus indicators |
| **Primary Gradient** | `linear-gradient(135deg, #6366F1, #3B82F6)` | Buttons and progress bar fills |
| **Success Emerald** | `#22C55E` | Active streaks, completed tasks, 100% accuracy progress ring |
| **Warning Amber** | `#F59E0B` | Pending tasks, discipline alerts, medium priority badges |
| **Danger Rose** | `#EF4444` | High priority tags, delete buttons, destructive warnings |
| **Main Text Color** | `#FFFFFF` | Pure white for headers, card titles, and high-contrast text |
| **Muted Text Color** | `#94A3B8` | Slate gray for subtitles, timestamps, and secondary info |
| **Glass Border Light** | `rgba(255, 255, 255, 0.08)` | Subtle 1px container outline |
| **Glass Border Focus** | `rgba(99, 102, 241, 0.40)` | Active focus ring & highlighted card border |

---

## 2. Live Screenshot Evidence & Visual Audit

### 2.1 Landing Page & Auth Flow
![Landing Page](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/landing_page_1784795624041.png)
![Signup Form](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/signup_form_filled_1784795649669.png)

### 2.2 Dashboard (Home Tab)
![Dashboard Home](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/dashboard_initial_1784795661331.png)

### 2.3 Goals Management & Creation Modal
![Goals Empty State](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/goals_empty_state_1784795696426.png)
![Create Goal Form](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/create_goal_form_1784795704042.png)
![Goals System Active Card](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/edit_goal_success_1784795803880.png)

### 2.4 Tasks & Today's Forge
![Create Task Form](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/create_task_form_1784795916472.png)
![Task Completed](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/task_completed_1784795945099.png)

### 2.5 Focus Pomodoro Session & Soundscapes
![Focus Timer Running](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/focus_timer_running_1784795976932.png)

### 2.6 System Logs & Notes
![Notes Empty State](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/notes_empty_state_1784796023251.png)
![Note Content Typed](file:///C:/Users/sundar/.gemini/antigravity-ide/brain/5eaebae9-ef96-44b8-960a-7ba1e22421e4/note_content_typed_1784795624041.png)

---

## 3. Exhaustive Screen Specifications & Workflows

### 3.1 App Layout Shell
- **Sidebar Navigation**: Fixed left bar with `GoalForge` icon brand logo, 5 navigation items (`Home`, `Goals`, `Tasks`, `Notes`, `Focus`), and a bottom-left `FORGE FOCUS` card displaying the current starred focus goal.
- **Top Header Bar**: User greeting ("Hey, <name> 👋"), daily productivity quote, top-right header actions (`Schedule Event`, `AI Sparkles`, `Theme Toggle`, `Profile Avatar`).

### 3.2 Dashboard (Home)
- **Recruit Rank Progress Banner**: Displays current user level (Level 1 - Recruit), Total XP earned, progress bar to Level 2 (100 XP threshold), Discipline Score (e.g. 40), and dynamic insight pill.
- **Quick Thoughts Widget**: Top-right collapsible drawer supporting instant 1-click note capture.
- **Upcoming Events Widget**: Displays scheduled agenda items with a direct `+ Schedule your first event` CTA.
- **Today's Accuracy Widget**: Circular green progress ring (`100%`) with "Elite Performance" pill.
- **Deep Work Widget**: Displays active focus time timer (`00:00 HRS`) with blue `Start Session >` primary CTA button.
- **Weekly Performance Widget**: Summary cards for 7-day accuracy and deep work hours.

### 3.3 Goals System & Habit Builder
- **Summary Metrics Bar**: `AVG MASTERY %`, `FINISHED`, `IN PROGRESS`, `MISSING DREAMS` (Archived goals).
- **Tab Switcher**: `Active Targets` (Target icon) vs `Missing Dreams` (Moon icon).
- **Goal Card Components**:
  - Category tag pill (e.g., `GENERAL`, `HEALTH`, `CAREER`).
  - Action buttons: Yellow Star (Set as Focus Goal), Moon (Archive), Pencil (Edit Goal), Trash (Delete Goal), Expand Chevron.
  - Circular Mastery percentage ring (`0% MASTERY`).
  - Goal Title and linear gradient progress bar.
  - Metadata pills: Deadline, Flame streak icon (`0/90`), Task counter (`0/1`).

### 3.4 Today's Forge (Tasks & Habits)
- **Header Summary**: Displays `TOTAL` tasks, `DONE` tasks, and `FOCUS %`.
- **Search Bar**: Instant real-time task filtering (`Search tasks instantly...`).
- **Task Item Architecture**:
  - Checkbox toggle with instant scale bounce micro-animation.
  - Tag pills (`DAILY`, priority flame `1d`).
  - Completed strike-through visual feedback in emerald green (`#22C55E`).
  - Trash delete icon.

### 3.5 Focus Sessions (Pomodoro Timer)
- **Timer Presets**: `25m`, `45m`, `90m`, and custom minute input.
- **Central Timer Ring**: Displays remaining time (`24:51`), status label (`NEURAL SYNC ACTIVE`), and active linked goal/task header.
- **Timer Controls**: Bright orange primary button (`PAUSE SESSION`), dark reset button (`Reset`).
- **Alert Configuration Panel**: Soundscape selectors (`ZEN`, `CYBER`, `BELL`, `ALARM`) with horizontal volume slider.

### 3.6 System Logs & Notes
- **Notes Navigation**: Category filter tabs, search field, "+ New Record" primary button.
- **Rich Editor Canvas**: Note title, category folder input (`Study`, `Personal`, `System`), rich content formatting canvas with auto-saving status indicator.

---

## 4. UI/UX Micro-Interactions, Animations & States

1. **Habit & Task Checkoff**: 1-Tap checkbox click triggers immediate scale bounce animation, turns check mark emerald green (`#22C55E`), applies strike-through on text, and awards `+50 XP`.
2. **Focus Timer State**: Circular progress ring ticks smoothly every second, updating remaining time label. Pause button transitions to yellow/orange glow.
3. **Empty States**: Clear dark cards with centered icons, descriptive text, and primary CTA buttons (`+ Forge Your First Goal`, `+ Add Task`, `+ New Record`).
4. **Loading & Transitions**: Smooth opacity fades (`0.15s ease-in-out`) between tabs and modal dialog overlays.
