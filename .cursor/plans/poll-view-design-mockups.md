# Poll view — design ideas to fill empty space

Context from code: `PollCardView` positions the title high (~22% height) and the options block at mid-screen (~50%), so a large lower zone stays visually empty. `Poll` already has `activityDate`, `activityDescription`, and `imageURL` (used in `MoreDetailsPopupView` / create flow) but the card does not surface them.

**Theme:** keep `AuthTheme` — black background, white primary text, 60% white secondary, cyan `#00D4FF` accent.

---

## Idea A — Activity teaser strip (uses existing poll fields)

- **Top of card (below title):** horizontal row with calendar icon + formatted `activityDate` (and optional time).
- **Middle:** optional thumbnail from `imageURL` (rounded, fixed height ~120pt) or placeholder “Add details” only for creator.
- **Below options:** 2-line clamped `activityDescription` with “More” tappable → same as ellipsis / more details.
- **Fills:** upper gap between title and buttons; lower gap with description + image.

## Idea B — “Context chips” + swipe affordance

- **Under vote count:** row of pills: `Activity` (date), `You voted` / `Tap to vote`, `2 people` (total voters — already derivable).
- **Bottom of card (above inner padding):** subtle hint row: “Swipe card to see next poll” with chevron — educates and uses dead space.
- **Fills:** horizontal bands; no new backend if you skip participant avatars initially.

## Idea C — Split layout (dense, less “floating”)

- Replace pure `position()` centering with a **top-aligned `VStack`** inside the card: title → meta row → optional image → options → confirm → progress → percentages → spacer `Spacer(minLength: 0)` so content sits from top down and **natural spacing** consumes height.
- **Fills:** removes the artificial void by layout change alone; easiest engineering win.

## Idea D — Ambient + micro-stats

- Very subtle dark gradient or dot grid in the card’s lower third (low contrast, AuthTheme-safe).
- Overlay small stat row: “Yes leads” / tie copy, or mini segmented bar label under the main bar.
- **Fills:** decorative + informational; keep subtle so it does not fight the cyan CTA.

## Idea E — Social preview (needs data or future work)

- “Shared with” avatar stack (first 3 `visibleToUids` resolved to initials) — requires profile fetch or denormalized names on poll.
- **Fills:** human context; higher effort.

---

## Mockup images

Generated mockups (open these files locally):

| Idea | File (in repo) |
|------|----------------|
| **A — Activity teaser** (date, image strip, description, More) | [`background/design-mockups/poll-mockup-idea-a-activity-teaser.png`](../../background/design-mockups/poll-mockup-idea-a-activity-teaser.png) |
| **B — Chips + swipe hint** | [`background/design-mockups/poll-mockup-idea-b-chips-swipe-hint.png`](../../background/design-mockups/poll-mockup-idea-b-chips-swipe-hint.png) |
| **C — Stacked layout + ambient lower zone** | [`background/design-mockups/poll-mockup-idea-c-stacked-ambient.png`](../../background/design-mockups/poll-mockup-idea-c-stacked-ambient.png) |

Use these for supervisor review; implementation can mix **A + C** for maximum impact with data you already store on `Poll`.
