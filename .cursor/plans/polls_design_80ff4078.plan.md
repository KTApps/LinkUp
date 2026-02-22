---
name: Polls design
overview: "Enhance the Polls screen with a full visual refresh and rich motion: card identity, progress bars, accent-driven hierarchy, and animated interactions so it feels like a modern tech product while staying within AuthTheme."
todos: []
isProject: false
---

# Polls design enhancement

## Current state

- **[PollsView.swift](LinkUp/Polls/PollsView.swift)** — ScrollView of poll cards; custom header with profile, chart, settings. Uses `AuthTheme.background`.
- **[PollCardView.swift](LinkUp/Polls/PollCardView.swift)** — Single card: question, vote count, Yes/No buttons, plain percentage text (`"50% 50%"`). Selected option uses `AuthTheme.accent`; card uses `AuthTheme.primary.opacity(0.06)` and 12pt corners. No progress bars or motion.
- **[AuthTheme.swift](LinkUp/Authentication/AuthTheme.swift)** — Black background, white primary, 60% secondary, cyan accent `#00D4FF`. All changes must use this palette.
- **[Poll.swift](LinkUp/Polls/Poll.swift)** — `Poll` / `PollOption` model; no changes needed for design-only work.

## Design direction (from your choices)

- **Scope:** Full visual refresh (hierarchy, accent usage, progress, card identity) plus rich motion (animated progress, staggered reveals, micro-interactions).
- **Constraints:** Follow [app theme rules](.cursor/rules/app-theme-colors.mdc): layout/structure from any reference is fine; colors must stay AuthTheme only.

---

## 1. Card visual identity

- **Elevation and shape:** Keep rounded corners; add a very subtle border (e.g. `AuthTheme.primary.opacity(0.08)`) or a light shadow so cards read as surfaces. Avoid grey outside the theme.
- **Background:** Consider a slightly stronger card background (e.g. `AuthTheme.primary.opacity(0.08)`) so cards separate clearly from the black background while staying dark.
- **Hierarchy:** Use [Typography](LinkUp/Typography.swift) consistently: stronger weight for the question (already headline), subheadline for vote count; consider a small accent detail (e.g. thin accent line or dot next to “X votes”) to tie cards to the theme.

## 2. Progress visualization

- **Replace text-only percentages** in `percentagesView` with a single horizontal **progress bar**:
  - One segment per option; segment width = share of total votes.
  - Use `AuthTheme.accent` for the leading segment(s) and a muted segment (e.g. `AuthTheme.primary.opacity(0.2)`) for the rest so it stays readable on black.
  - For two options (Yes/No), a two-segment bar is enough; keep optional “50% / 50%” as secondary text if desired.
- **Layout:** Place the bar below the option buttons; ensure it doesn’t dominate the card (fixed height, e.g. 6–8pt).

## 3. Selected state and option buttons

- **Selected state:** Keep accent fill for the selected option; ensure contrast (e.g. background text on accent). Add a clear **selected indicator** (e.g. checkmark icon or accent border) so “voted” is obvious at a glance.
- **Tap feedback:** Add a brief scale or opacity animation on button tap (e.g. `scaleEffect` or `animation(.easeOut(duration: 0.15))` on press) for a responsive feel.
- **Disabled after vote:** Consider disabling further taps after a selection (or show “You voted Yes”) to avoid accidental double-vote and to support future backend rules.

## 4. Rich motion

- **Animated progress bar:** When `poll.options` change (user votes), animate the segment widths (e.g. `Animation.easeOut(duration: 0.35)`) so the bar grows/shrinks smoothly instead of jumping.
- **Staggered card appearance:** On first load, animate each `PollCardView` with a short delay (e.g. 0.05–0.1s per index) and a subtle transition (e.g. opacity + slight vertical offset or scale) so cards “land” in place.
- **Micro-interactions:** Button press animation (above); optional subtle hover/press state for header icons (chart, settings) using accent tint on tap.

## 5. List and header polish

- **Spacing:** Keep or slightly increase spacing between cards (already proportional in `PollsView`); ensure internal card padding and alignment are consistent.
- **Header:** Leave structure as-is; optional: use accent for the active or touched state on chart/settings icons so the top bar feels cohesive with the new card style.

## 6. Implementation order

- Implement in **PollCardView** first (card background/border, progress bar, selected state, button animation, progress animation).
- Then in **PollsView**: staggered appearance for the `ForEach` of cards (using index and `onAppear` or a small delay state).
- No data model changes; all behavior remains in-memory voting.

## Files to touch


| File                                                               | Changes                                                                               |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| [LinkUp/Polls/PollCardView.swift](LinkUp/Polls/PollCardView.swift) | Card styling, progress bar view, selected indicator, tap animation, animated progress |
| [LinkUp/Polls/PollsView.swift](LinkUp/Polls/PollsView.swift)       | Staggered reveal for poll cards; optional header icon feedback                        |


## Out of scope (for this plan)

- Backend or Firestore integration.
- Changing AuthTheme or adding new colors.
- Bottom tab bar or navigation structure changes.

