# Dissertation structure (LinkUp)

This file records the **intended essay/dissertation outline** and **evaluation approach** for LinkUp so project work stays aligned with the write-up. Word counts are targets for a ~12,000-word body (confirm whether your department counts abstract, references, and appendices).

---

## Project context (short)

- **Artefact:** LinkUp — iOS app (Swift/SwiftUI) for informal group scheduling: availability, overlap/matching, polls, groups, Firebase (Auth, Firestore).
- **Written work:** ~12k-word dissertation describing the problem (literature), requirements, design, implementation, security/privacy, **iterative user evaluation**, discussion, conclusion.
- **Evaluation plan:** After implementation, recruit **target users from the public** → test the app → collect feedback → **improve the app** → send a revised build back for a **second round** of testing/feedback.

---

## Main chapters and word targets

| # | Chapter | Approx. words | Purpose |
|---|---------|----------------|---------|
| — | Title, contents, lists | *(excluded from count)* | As required by the school. |
| 1 | **Abstract** | 250–350 | Problem, approach, artefact, **two-round** user evaluation, main outcome/limitation. |
| 2 | **Introduction** | 1,000–1,300 | Motivation, aims, scope (MVP, iOS), **evaluation strategy** (iterative public testing), dissertation roadmap. |
| 3 | **Literature review** | 1,800–2,200 | Related work and theory; aligns with `LITERATURE_REVIEW.md`. |
| 4 | **Requirements and scope** | 700–900 | Functional/non-functional requirements; **definition of target users** (feeds recruitment criteria). |
| 5 | **Research design, ethics and data protection** | 900–1,200 | Public recruitment, inclusion/exclusion, consent, anonymity, storage of feedback, study **protocol** (tasks, sessions, questionnaires/interviews); institutional ethics if required. |
| 6 | **System design and architecture** | 1,600–1,900 | High-level architecture, data model, key design decisions; aligns with `SYSTEM_ARCHITECTURE_PLAN.md` / implementation plan. |
| 7 | **Implementation** | 1,700–2,000 | Feature-by-feature realisation; aligns with `IMPLEMENTATION_PLAN.md`. |
| 8 | **Security and privacy (system)** | 500–700 | Auth, Firestore rules, client checks; ties to “privacy by design” from the literature; see `FIRESTORE-SECURITY-RULES-EXPLAINED.md`. |
| 9 | **User evaluation** | 1,800–2,400 | **Round 1:** method, participants, findings/themes → **changes implemented** from feedback → **Round 2:** method, findings, comparison → limitations. |
| 10 | **Discussion** | 900–1,100 | Findings vs literature; what iteration did or did not resolve. |
| 11 | **Conclusion and future work** | 550–750 | Contribution, limitations, next steps. |
| — | **References** | *(usually excluded)* | |
| — | **Appendices** *(optional)* | *(often excluded)* | Consent, task scripts, questionnaires, extra figures/screenshots. |

**Rough total (chapters 2–11):** ~11,000–12,200 words, plus abstract.

If the module mandates a single **Methodology** chapter, use that title for chapter 5 and keep the same content (ethics + protocol).

---

## Iterative evaluation workflow (for chapter 9)

1. **Round 1:** Recruit target audience → structured testing (tasks, observation, surveys/interviews as planned) → record issues, themes, and priorities.
2. **Redesign / implementation:** Change the app from feedback; document **what** changed and **why** (traceability to participant comments).
3. **Round 2:** Same or new participants (as methodology allows) → repeat evaluation → compare to round 1 (e.g. severity of issues, task success, satisfaction).

---

## Related files in this repo

| File | Role |
|------|------|
| `background/LITERATURE_REVIEW.md` | Draft literature review text and references. |
| `background/IMPLEMENTATION_PLAN.md` | MVP features and implementation checklist. |
| `background/SYSTEM_ARCHITECTURE_PLAN.md` | Architecture outline and design rationale. |
| `background/FIRESTORE-SECURITY-RULES-EXPLAINED.md` | Security rules narrative for chapter 8. |
| `background/dissertation-structure.md` | This outline (update if the handbook or plan changes). |
| `background/requirements-and-scope.md` | Draft requirements, scope, and traceability for chapter 4. |

---

*Update this document if word limits, chapter titles, or evaluation design change.*
