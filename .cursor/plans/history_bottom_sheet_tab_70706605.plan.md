---
name: History bottom sheet tab
overview: Remove the polls header bar-chart entry, add a fourth bottom bar tab that presents Poll History in a draggable sheet at 75% screen height, and delete the now-unused navigation push route.
todos:
  - id: contentview-sheet
    content: Add AppSheet.history, bottom bar button, history sheet branch with .fraction(0.75); remove AppRoute/navigationPath/push
    status: completed
  - id: pollsview-header
    content: Remove onOpenPollHistory and chart.bar header button; fix previews
    status: completed
  - id: pollhistory-comment
    content: Refresh PollHistoryView header comment for sheet entry point
    status: completed
  - id: build
    content: Verify xcodebuild for LinkUp scheme
    status: completed
isProject: false
---

# Poll History: bottom tab + 3/4 sheet

## Current behavior

- [ContentView.swift](LinkUp/ContentView.swift): `NavigationStack` + `navigationPath`; `onOpenPollHistory` appends `AppRoute.history`, which pushes [PollHistoryView](LinkUp/Polls/PollHistoryView.swift) via `.navigationDestination`.
- [PollsView.swift](LinkUp/Polls/PollsView.swift): Header `HStack` includes a `chart.bar.fill` button calling `onOpenPollHistory()` (lines ~410–417).

## Target behavior

- **No** bar chart (or history) control in the polls header — only profile, wordmark, and settings remain on the right cluster (remove the chart button and its `HStack` spacing if it becomes a single settings button).
- **New** bottom bar item (same pattern as Messages / Plus / Calendar): label **History**, SF Symbol `**chart.bar.fill`** (keeps the same metaphor as before).
- Tapping it sets `presentedSheet = .history` (extend [AppSheet](LinkUp/ContentView.swift) with a `history` case).
- Sheet content: reuse `**PollHistoryView(authState:polls:)`** inside a `**NavigationStack**` so its existing `.navigationTitle("History")`, `< Back` (`dismiss()`), settings toolbar, and nested chart sheet keep working.
- Apply `**.presentationDetents([.fraction(0.75)])**` and `**.presentationDragIndicator(.visible)**` on the **history** sheet only so it opens at **3/4 height** and can be dragged (other sheets stay default full-screen unless you choose otherwise).

Implementation note: because detents differ per sheet type, use a `**switch` on `sheet`** in the `.sheet(item:)` closure (or a small helper) so only the history branch gets the detent modifiers; other cases stay unchanged.

## Code changes (ordered)

1. **ContentView.swift**
  - Remove `AppRoute`, `@State navigationPath`, and `.navigationDestination(for: AppRoute.self)`.
  - Add `AppSheet.history` and a `barButton` for History (fourth item in `bottomBar`).
  - In `.sheet(item:)`, branch: for `.history`, present `NavigationStack { PollHistoryView(...) }` with `.frame` / `AuthTheme.background` as needed, then `**.presentationDetents([.fraction(0.75)])`** and `**.presentationDragIndicator(.visible)`**; for other cases, call existing `sheetContent(for:)`.
  - Stop passing `onOpenPollHistory` into `PollsView`.
2. **PollsView.swift**
  - Remove `var onOpenPollHistory: () -> Void` and the chart `Button` from `pollsHeader`.
  - Update call sites / previews: drop `onOpenPollHistory` from the struct and `#Preview` at the bottom.
3. **PollHistoryView.swift**
  - Update the file / struct comment to say history is opened from the **bottom bar sheet** (not the header). No behavioral change required if `dismiss()` already closes the sheet.
4. **Build**
  - Run `xcodebuild` (simulator) to confirm compile.

## UX details

- **3/4 vs full screen:** Your note says both; this plan uses **75% height** as the primary interpretation. Users can drag the sheet (with drag indicator) per system behavior.
- **Tab order:** Default proposal — **Messages | Plus | Calendar | History** (History last). Say if you want a different order.

