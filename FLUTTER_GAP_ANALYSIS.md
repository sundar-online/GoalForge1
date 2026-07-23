# GoalForge — Flutter Application Gap Analysis (FLUTTER_GAP_ANALYSIS.md)

This document provides a comprehensive audit comparing the authoritative web application product specification (`WEB_ANALYSIS.md`) with the current Flutter mobile codebase.

---

## 1. Feature & UI Gap Comparison Matrix

| System / Screen | Reference Web Product Spec | Current Flutter Codebase | Status / Gap Identified | Action Required | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Design System & Theme** | Dark `#0B0B14`, Card Surface `#161726`, Inset Input `#121321`, Primary Accent `#6366F1` / `#3B75FF`, Glass Border `rgba(255,255,255,0.08)` | Light theme default in `AppColors` (`#F4F7FF` background, `#3B75FF` primary, `#FFFFFF` surface) | ⚠️ **Mismatched Theme** | Refactor `AppColors` and `AppTheme` to dark space black glassmorphism | **P0 (Immediate)** |
| **App Navigation Shell** | Top Header (Level XP bar, greeting quote, quick actions) + Sidebar (Desktop) / Bottom Nav Bar (5 Tabs) | `MainNavigationPage` with `CustomBottomNavBar` (5 tabs) | 🟡 **Visual Alignment Needed** | Update top header banner, level progress indicator, and dark navbar styling | **P1 (High)** |
| **Dashboard / Home** | Recruit level banner card, Focus Goal banner, Quick Thoughts collapsible drawer, Today's Accuracy 100% green ring, Deep Work timer widget, Weekly performance stats | `HomePage`, `DashboardBloc`, `AiInsightsService` | 🟡 **Visual Alignment Needed** | Apply dark card styling (`#161726`), circular accuracy ring (`#22C55E`), and deep work widget CTA | **P1 (High)** |
| **Goals Management** | Summary metrics bar (`AVG MASTERY`, `FINISHED`, `IN PROGRESS`, `MISSING DREAMS`), `Active Targets` vs `Missing Dreams` tab switcher, circular mastery percentage ring, yellow star focus goal toggle | `GoalsPage`, `GoalsBloc`, `GoalsRepository` | 🟡 **Workflow & UI Gap** | Add summary metrics bar, `Missing Dreams` tab, circular mastery ring, and focus goal toggle | **P1 (High)** |
| **Today's Forge (Tasks & Habits)** | Header summary (`TOTAL`, `DONE`, `FOCUS %`), instant search input bar, priority pills, completed strike-through in emerald green (`#22C55E`), 1-tap checkoff scale animation | `TodayForgePage`, `TasksBloc`, `HabitsBloc` | 🟡 **Micro-interactions & Styling Gap** | Add header summary bar, instant search input, priority tag styling, and checkoff micro-animations | **P1 (High)** |
| **Focus Sessions** | Glowing Pomodoro timer ring, presets (`25m`, `45m`, `90m`), alert soundscapes (`ZEN`, `CYBER`, `BELL`, `ALARM`) with volume slider, orange `PAUSE SESSION` CTA | `FocusSessionPage`, `FocusBloc`, `FocusRepository` | 🟡 **Soundscapes & UI Gap** | Add soundscape selector pills, volume slider control, and orange pause CTA button | **P2 (Medium)** |
| **System Logs & Notes** | Sticky quick thought capture, folder categories (`Study`, `Personal`, `System`), rich content editor canvas, markdown preview modal | `SystemLogsPage`, `NotesBloc`, `NotesRepository` | 🟡 **Editor & Layout Gap** | Update category chips, folder input in note creation form, and markdown view modal | **P2 (Medium)** |
| **Calendar & Events** | Horizontal date switcher, Agenda timeline cards, event category pills | `EventsPage`, `EventsBloc`, `EventsRepository` | 🟡 **Agenda Styling Gap** | Align horizontal calendar date strip and agenda event card layout | **P2 (Medium)** |
| **Offline Sync Engine & Architecture** | Isar local DB persistence + Cloud Firestore Sync Engine, Clean Architecture, BLoC pattern | `LocalDatabaseService`, `SyncEngine`, BLoC classes | ✅ **Verified Safe** | Preserve Isar singleton safety, `.skip(1)` BLoC stream listeners, and offline-first queue | **P0 (Preserve)** |

---

## 2. Technical Implementation Roadmap & Priorities

1. **Step 1: Dark Glassmorphic Design System**: Refactor `AppColors` and `AppTheme` to implement `#0B0B14` space black background, `#161726` surface cards, `#121321` inputs, and `#6366F1` indigo primary accents.
2. **Step 2: Navigation Shell & Dashboard**: Update `MainNavigationPage` and `HomePage` with Recruit Rank banner, Level XP bar, Quick Thoughts drawer, and Today's Accuracy circular ring.
3. **Step 3: Goals Management System**: Update `GoalsPage` with Summary Metrics Bar, `Active Targets` vs `Missing Dreams` tab switcher, circular mastery ring, and yellow star focus toggle.
4. **Step 4: Today's Forge (Tasks & Habits)**: Update `TodayForgePage` with header metrics (`TOTAL`, `DONE`, `FOCUS %`), instant search input bar, priority pills, and emerald green completed text visual feedback.
5. **Step 5: Focus Pomodoro Sessions**: Update `FocusSessionPage` with preset pills (`25m`, `45m`, `90m`), alert soundscapes selector, volume slider, and orange pause session CTA.
6. **Step 6: System Logs & Notes**: Update `SystemLogsPage` with folder tags (`Study`, `Personal`), note editor form, and markdown detail modal.
7. **Step 7: Verification & Regression Testing**: Run `flutter analyze` (**0 errors**) and `flutter test` (**100% pass**).
