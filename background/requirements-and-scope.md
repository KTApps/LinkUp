# Requirements and scope

This chapter sets out who LinkUp is for, what the system was expected to do, and where I deliberately drew the line so the scope stayed realistic for a dissertation. I wrote the functional requirements in a testable way so I could refer back to them when describing the implementation and when analysing feedback from the user studies.

## Background and motivation

In practice, the people I had in mind usually arrange plans through messages and calls. That works up to a point, but it often leaves one person doing most of the chasing and makes it hard to settle on a time everyone accepts. LinkUp is my response: an iOS application that lets people connect as friends, talk in small groups, and use polls to agree on what to do and when. There is also a calendar-oriented view so agreed plans are easier to see in one place. The backend is Firebase (Authentication and Firestore), with security rules so people only access data they are meant to see.

## Target users and context

I designed LinkUp primarily for **informal social groups**—for example friends trying to fix a meet-up, or similar small circles who already know each other. I assumed users would have an iPhone that could run the app, that they would use **email and password** sign-up, and that they would usually be online while using it. Firestore can queue some work offline, but I did not treat full offline-first behaviour as a core requirement.

For the user studies I recruited participants who matched this picture; inclusion criteria, ethics, and procedure are in the methodology chapter. This section only clarifies **who the software was designed for**; how participants were recruited and what they did in the sessions is covered there.

## Functional requirements

I split requirements into “must have” for the minimum viable product and “should have” for features I treated as lower priority if I needed to narrow the build. The list below is what I held myself to while building.

**Must have**

1. **Account creation and sign-in.** New users register with email and password; returning users sign in. The app should show clear feedback when credentials are wrong or validation fails.
2. **User profile.** After authentication, the app stores and loads a profile tied to the Firebase user id (including at least username and email in my design).
3. **Session handling.** If someone is already signed in, they land in the main app; otherwise they see the login screen. Signing out returns them to login.
4. **Friends.** Users can add friends (for example by username) and see a list they can use when creating groups.
5. **Groups and messaging.** Users can create a named group from selected friends and exchange messages in that conversation.
6. **Polls: viewing and voting.** Users see polls that are meant for them (according to visibility rules I implemented), can vote for options, and see vote counts update.
7. **Polls: creating.** Users can create polls with a question and options, and attach further detail where the app supports it (such as an activity date, description, or image).
8. **Polls: results and history.** Users can explore results in more detail—charts, per-option breakdowns, history—following what the current interface provides.
9. **Confirming plans.** Where the app supports it, users can confirm they are happy with an outcome so that decision can feed into how plans appear elsewhere (for example on the calendar).
10. **Calendar.** Users can open a calendar that reflects confirmed or recorded dates linked to polls, so agreed times are not only buried in a thread.
11. **Settings.** Users can open settings, reach friend management from there, sign out, and delete their account where that flow exists.

**Should have**

12. **In-app notifications.** A list of notification items surfaced inside the app (for example backed by Firestore), including a sense of what is unread if the implementation supports it.
13. **Poll owner actions.** Whoever created a poll can carry out the extra actions the rules and UI allow, such as editing, deleting, or controlling who can see the poll.

## Non-functional requirements

Privacy and security matter because the app deals with who people are friends with, what groups they are in, and how they vote. I aimed for **least privilege**: users should only read and write data they are allowed to, which I enforced mainly through **Firestore security rules** and sensible checks in the client. Passwords are handled by Firebase Authentication; I do not store plaintext passwords in Firestore.

For **usability**, I wanted the main paths—signing in, making a poll, voting, opening messages—to be understandable without a manual, at a level that is reasonable for a student MVP rather than a polished consumer launch.

**Performance** was scoped to small groups and modest numbers of polls: responsive enough for normal use, without promising a formal service-level agreement. On **maintainability**, I kept the Xcode project organised by feature areas (authentication, friends, messages, polls, calendar) with shared styling and a single notion of signed-in state, which made it easier to work on one part without breaking others. Finally, I tried to **minimise data collection**: only store what friends, groups, polls, and confirmations actually need, and avoid extra personal fields without a clear purpose.

## Scope within the project

The work I counted as inside scope included: a native **iOS** app written in Swift and SwiftUI; use of **Firebase Authentication** and **Cloud Firestore** as the backend (and Storage where images are used); the user journeys from account and friends through groups and messaging to creating and participating in polls, then viewing results, history, calendar, and settings. The written dissertation also covers how I designed and built this, how security was handled, and how I evaluated the app with users in two rounds of feedback and iteration.

## Scope outside the project

It is important to be explicit about what I did **not** attempt, so examiners are not looking for features I never promised.

I did not build **Android, web, or desktop** versions. There is no **deep link into Apple Calendar or Google Calendar** for two-way sync or importing free/busy blocks from those systems.

The literature review discusses tools like availability grids and overlap-based suggestions. In this MVP I focused on **polls and group chat** as the main way to converge on a time. I did **not** implement a separate “paint your free time” grid or an engine that automatically computes intersection of everyone’s availability across arbitrary date ranges. If I add that later, it would be a clear extension beyond what is described here. Likewise, I did not implement a full **push notification** pipeline through APNs/FCM for production; in-app notification listing is a lighter-weight step.

I did not treat **payments, ticketing, or maps** as product pillars. Optional location fields on a poll are a small extra, not a mapping product. I also did not require a **public App Store launch**; distributing builds through TestFlight or ad-hoc installs for study participants was enough for this project.

## Constraints

A practical constraint was the need to keep the artefact **focused and evaluable**: I prioritised a coherent **end-to-end slice** (one iOS client and one backend) so the main user journeys could be implemented, secured, and tested properly, rather than spreading effort across many platforms or half-finished features. User studies with members of the public required **ethical approval and consent**, set out in the methodology chapter rather than repeated in full here. Finally, the app relies on **Firebase and Apple’s toolchain** (Xcode, iOS SDK); quotas, SDK behaviour, and policy changes there were outside my control.

## Traceability to the implementation

For assessment purposes it is useful to show where these requirements land in the codebase. Authentication, sign-up, and session handling sit in the **Authentication** module; the user profile document lives in Firestore under each user id. **Friends** and **Messages** (including group creation) are implemented in their own feature folders. **Polls**—deck, voting, creation, results, charts, history, and owner flows—are concentrated in the **Polls** module, with confirmations feeding the **Calendar** module. **Settings** (including friend entry points, sign-out, delete account, and the notification list) sits with the authentication-related UI. Security rules in **firestore.rules** back up the privacy and access requirements described above. Those areas are described in more detail in the implementation chapter.