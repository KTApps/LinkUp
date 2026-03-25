# Poll card media — plan-mode prompt

Paste the block below into **plan mode** to generate the implementation plan.

---

**Create a detailed implementation plan** and save it as **`/Users/kmaha/Dev/LinkUp/.cursor/plans/poll-card-media.plan.md`** (short hyphenated filename). Use the project’s usual plan format: YAML frontmatter with **`name`**, **`overview`**, and **`todos`** (concrete checklist), then markdown sections.

**Project context:** LinkUp is SwiftUI + Firebase/Firestore. Use **`AuthTheme`** (`background`, `primary`, `secondary`, `accent`) for all UI — no mockup greys/blues. Firebase SDK **10.22.1**. Xcode **15.4**. Existing poll deck lives in **`PollsView`** + **`PollCardView`**; **`MoreDetailsPopupView`** is used from **`PollsView`** (overlay) and **`CalendarView`** (with Unconfirm). **`Poll`** is in **`LinkUp/Polls/Poll.swift`** with `imageURL` (single string), `activityDate`, `activityDescription`; **`PollService`** / **`CreatePollView`** handle one image upload per poll.

---

### Product spec (must all appear in the plan; do not paraphrase away constraints)

1. **Card layout — full-bleed media**  
   Replace the current flat card background with a **media-first** card: the main area is either a **photo** and/or a **map** (see paging rules below). All primary chrome sits **on top** of whichever page is visible (image or map), TikTok-style, with **gradients/scrims** so **title, date, description, poll options, confirm, vote counts, progress bar, and percentage row** remain **clearly readable**.

2. **Overlay regions**  
   - **Top of media:** `poll.question` (title) and **date/time** using the **same formatting intent** as `MoreDetailsPopupView` today (time · calendar date; show a sensible “no date” line if `activityDate` is nil).  
   - **Bottom of media:** **Description** (`activityDescription`): show **1–2 lines** truncated with **`…more`**; tapping **`…more`** expands to full text (TikTok-style). If empty, omit the description block or show a minimal empty state consistent with the design.  
   - **Below description on the same bottom stack:** existing **poll options**, **Confirm** button, **progress bar**, and **percentage row** (same behaviors as today: vote highlighting, confirmed state, disabled rules).

3. **Single tap on media**  
   **Single tap** on the **visible** media page (photo **or** map) **toggles** visibility of **all** overlay chrome listed in (2) (top + bottom). Second tap restores it. When chrome is hidden, the user still sees full-bleed media.

4. **Paging — image vs map**  
   - **At most one photo** per poll (`imageURL` or future single-URL field; **legacy** documents: existing **`imageURL` counts as that one photo**).  
   - **No** pulling images from other polls; **each new poll** uses a **fresh upload** in create/edit flow (no “pick from past polls” gallery).  
   - **Location:** not implemented end-to-end yet. Plan must add a **Create Poll placeholder** for “pin on map” (e.g. disabled UI copy or stub section) and, if needed, **optional model/Firestore fields** for coordinates for forward compatibility — but **no** full pin workflow required in this plan if it would block shipping; document follow-up.  
   - **If the poll has a photo but no location:** only **one** “page” — the photo. **No** autoplay loop.  
   - **If the poll has location but no photo:** only **one** page — the **map**.  
   - **If both photo and location:** **two** pages. **Autoplay** switches **image → map → image → …** every **5 seconds**. **Double-tap** on the media switches page **manually** (image ↔ map). **Do not** use vertical swipe between pages (avoid gesture conflict with horizontal deck swipe).  
   - **If neither photo nor location:** **minimal** empty middle: **no** fake map or stock photo; subtle **`AuthTheme`**-consistent filler (e.g. soft gradient or low-contrast pattern) so the card still has structure; overlays (title/date/poll UI) still apply as far as data allows.

5. **Map behavior**  
   When the map page is shown: use **SwiftUI `Map` / MapKit** with a marker at the activity coordinate when available. Allow **standard map gestures** (including pan/zoom as the SDK provides). **No** extra on-map UI (no custom compass button, scale control, or redundant chrome) unless the system provides it by default and cannot be removed — prefer minimal styling.

6. **Gesture conflicts**  
   - Preserve **horizontal** deck swipe on the **top card** in **`PollsView`** as today.  
   - Implement **double-tap vs single-tap** so a **double-tap does not** fire **two** overlay toggles (document approach: e.g. gesture priority, delay, or UIKit bridge if needed).

7. **Ellipsis and More details**  
   - **Non-owners:** **Remove** the ellipsis entirely from **`PollCardView`** (no path to more-details overlay).  
   - **Owners:** Keep ellipsis opening the **owner actions sheet**; **remove** the **“More details”** row; keep **Edit** and **Delete** (and any other existing non-details actions).  
   - **`PollsView`:** Remove **`pollForMoreDetails`**, **`moreDetailsOverlay`**, and any code that presents **`MoreDetailsPopupView`** from the poll deck.  
   - **`CalendarView`:** **Keep** **`MoreDetailsPopupView`** unchanged for day-detail flow, including **Unconfirm**.

8. **Files and layering**  
   The plan must name likely touched files (e.g. **`PollCardView.swift`**, **`PollsView.swift`**, **`CreatePollView.swift`**, **`Poll.swift`**, **`PollService.swift`**, **`MoreDetailsPopupView.swift`** only if shared pieces are extracted, previews). Prefer **small extracted subviews** (e.g. media pager + overlay) if it keeps **`PollCardView`** maintainable.

9. **Build discipline**  
   Break work into **ordered steps**. After **each** step, the **app must still compile** (`xcodebuild` or Xcode). Call out any **Firestore** encoding changes and backward compatibility for **`imageURL`** and new optional location fields.

10. **Previews**  
    Update or add SwiftUI previews covering: image-only, map-only (mock coordinate), both pages, neither (minimal), and confirmed vote state if practical.

---

**End of prompt for plan mode.**
