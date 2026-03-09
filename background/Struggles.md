# Struggles

This document collects the main struggles I faced while building the LinkUp app. Each one is explained with enough technical detail for readers with a software background (e.g. listeners, state, Firestore, security rules). Every new struggle uses the same structure below.

---

## 1. Shared polls not showing for the other person

**The struggle**  
Person A created a poll and shared it with a group that included Person B. Person B could see the new group in the Messages tab, but when they opened the main poll feed they saw "No polls" instead of the one that had been shared with them.

**How I found out**  
I tested by logging in as Person B after Person A had created and shared the poll. The feed was empty even though the group (and thus the share) existed.

**How I diagnosed it**  
In `ContentView` the poll feed attaches a Firestore snapshot listener (`addPollsListener`) that queries `polls` where `visibleToUids` array-contains the current user's uid. The guard that registered the listener used `authState.currentUser?.id`—that comes from the Firestore user profile document, which is loaded asynchronously after sign-in. When Person B first landed on the feed, `onAppear` ran before the profile had loaded, so `currentUser` was nil and the listener was never attached. No query, no polls.

**How I fixed it**  
I switched the guard to use `authState.authRef.currentUser?.uid` (Firebase Auth's UID), which is available as soon as the user is signed in. The listener now attaches in `ContentView.onAppear` immediately, so the feed populates without waiting for the profile fetch.

---

## 2. Vote counts disappearing after leaving the screen

**The struggle**  
When someone voted on a poll they saw the count go up (e.g. "1 vote"). But when they signed out and signed back in, or when another person looked at the same poll, the count showed zero. The vote did not seem to be saved.

**How I found out**  
I voted as Person A, saw "1 vote," then signed in as Person B and saw "0 votes" on the same poll. Person A also saw "0 votes" after signing back in.

**How I diagnosed it**  
I added logging in `PollService.submitVote`: we read the poll doc, increment the option count, then batch `updateData` on the poll document (the `options` array) and `setData` on `polls/{pollId}/responses/{uid}`. The batch commit was succeeding from the client's perspective, but the console showed "Write at polls/... failed: Missing or insufficient permissions." So the Firestore security rules were rejecting the update. The poll read rule had been tightened to `uid in resource.data.visibleToUids`, but the update rule had not been deployed (or was still the old one). I also ensured the `options` field we write (array of `{ id, text, count }`) is stored in a form that decodes correctly when we read the document back as `Poll`.

**How I fixed it**  
I updated the Firestore rules so the poll document allows `update` when `request.auth.uid in resource.data.visibleToUids`, then deployed rules and indexes. I also write the options array as plain `[[String: Any]]` in the batch so the stored shape matches what `Poll`/`PollOption` expect when decoding, so counts persist for all clients.

---

## 3. One vote per poll and showing the user's choice when they return

**The struggle**  
I wanted each person to have at most one vote per poll (they could change their mind, but not vote for multiple options). I also wanted their chosen option to be clearly highlighted (e.g. in cyan) when they came back to the poll later.

**How I found out**  
This was a design requirement rather than something I "discovered" broken. I implemented it by having the app remember each user's vote per poll and pass that information into the poll card so it could highlight the right option.

**How I diagnosed it**  
The backend already enforced one vote per user per poll: `polls/{pollId}/responses/{uid}` is a single document storing `{ optionId, username }`. So the data model was fine. The gap was on the client: we never loaded "my vote" when building the feed or when rendering a card, and we didn't pass it into the card so it could set the selected option. I confirmed that the card's selected state was purely local and not keyed by poll id when the view was reused.

**How I fixed it**  
I added `fetchMyVote(pollId)` in `PollService` (reads `polls/{pollId}/responses/{uid}` and returns `optionId`). In `PollsView` I keep a `myVotes: [String: String]` (pollId → optionId), populated in a `.task(id: polls.map(\.id))` that calls `fetchMyVote` for each poll. Each `PollCardView` gets `myVoteOptionId: myVotes[poll.id]` and uses it in `onAppear` and `onChange` to set its local `selectedOptionId`. After a successful `submitVote` we set `myVotes[pollId] = optionId` so the UI updates without an extra fetch.

---

## 4. Wrong poll showing a selected option

**The struggle**  
Person A had voted "Yes" on a poll called "running?". When they looked at a different poll, "climbing?", which had zero votes, the "Yes" option on "climbing?" also appeared selected (highlighted), as if they had voted on it too.

**How I found out**  
I saw that one poll showed 0 votes but still had an option highlighted, and realised the highlight was "carrying over" from another poll.

**How I diagnosed it**  
The deck reuses the same `PollCardView` instances for different polls when you swipe (we only have a few card views bound to `polls[0]`, `polls[1]`, `polls[count-1]`). Each card holds `@State private var selectedOptionId`. When the binding `poll` changed to a different poll (e.g. after sending the top card to the back), we never reset `selectedOptionId`, so the card showed the previous poll's selection for the new poll's data.

**How I fixed it**  
I added `.onChange(of: poll.id)` in `PollCardView`: when the poll id changes (card reused for another poll), we set `selectedOptionId = myVoteOptionId` so the displayed selection always matches the current poll's saved vote (or nil if they haven't voted on that poll).

---

## 5. The card stack advancing on its own after voting

**The struggle**  
When Person B voted on the second poll in the stack, the app behaved as if they had swiped: the current poll moved to the back and the next one came to the front, even though they had not swiped.

**How I found out**  
I tested with two accounts and two polls. After voting on the second poll, the stack advanced by itself.

**How I diagnosed it**  
I added `[Deck]` logging: when the Firestore listener fired (after we updated the poll document on vote), we were doing `polls = newPolls` in the listener callback. That replaced the entire array with the server's query order (e.g. `createdAt` desc), so any local order from swiping was lost and the "top" card (index 0) changed. In addition, that full list replace caused a big re-render; the drag gesture's `onEnded` could fire with a large translation and trigger `sendTopCardToBack`, so the stack advanced without a real swipe.

**How I fixed it**  
In the listener callback in `ContentView` I no longer assign `polls = newPolls`. Instead I merge: I keep the current `polls.map(\.id)` order, build a `newById` map from `newPolls`, then fill a `merged` array by iterating over the current ids (deduped) and looking up each poll in `newById`, then appending any new poll ids from the server. I set `polls = merged`. So the deck order is preserved and only poll data (e.g. option counts) is updated when the snapshot fires after a vote.

---

## 6. The same poll appearing twice in the stack

**The struggle**  
After adding a new poll (e.g. "jumping?") and swiping through the stack, the user saw "jumping?" again later in the stack. The same poll appeared more than once.

**How I found out**  
I added the new poll, swiped through the cards, and noticed the same poll title and content appearing again.

**How I diagnosed it**  
I logged the poll ids when merging. The same poll id appeared at two indices (e.g. index 0 and index 3). The merge logic was "for each id in currentIds, append the poll from newById" and "for each new poll not in currentIds, append." If `currentIds` already contained duplicates (e.g. from a prior bug or race), we were preserving them, so the merged list had the same poll twice.

**How I fixed it**  
When building `merged`, I iterate over `currentIds` but only add a poll the first time we see its id (using a `Set<String>` of seen ids). So we deduplicate by poll id while preserving order; then we append any polls from the server that aren't in that set. The stack never shows the same poll twice.

---

## Summary

| # | Issue | What happened | Root cause | Fix |
|---|-------|----------------|------------|-----|
| 1 | Shared poll not showing | Person B saw "No polls" despite being in the shared group | Listener guard used profile id (loaded async); listener never attached | Use Firebase Auth uid in ContentView so listener attaches on sign-in |
| 2 | Vote count not persisting | Votes showed then disappeared for everyone | Firestore rules rejected poll update; options encoding/decoding shape | Deploy rules (update if uid in visibleToUids); write options as plain maps |
| 3 | One vote + highlight | Requirement to limit to one vote per poll and show it on return | No client-side load of "my vote" or pass-through to card | fetchMyVote; myVotes state; pass myVoteOptionId into PollCardView |
| 4 | Wrong poll highlighted | One poll showed another poll's selection | Reused card kept @State selectedOptionId when poll binding changed | .onChange(of: poll.id) → set selectedOptionId = myVoteOptionId |
| 5 | Stack advancing after vote | Deck moved to next poll without a swipe | Listener did polls = newPolls; order reset + gesture fired on re-render | Merge: preserve current order, update poll data from snapshot only |
| 6 | Same poll twice in stack | Same poll appeared again after swiping | Merge preserved duplicate ids in currentIds | Deduplicate by id when building merged (Set of seen ids) |
