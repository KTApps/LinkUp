# Initial plan – Student Social Scheduling: Designing an Automated Solution to Reduce Coordination Barriers

**Author:** Kelvin Mahaja – 23097798  
**Supervisor:** Nervo Verdezoto Dias

---

## Project Description

This project investigates how scheduling difficulties impact university students' social lives and whether an automated group availability tool could reduce these coordination barriers. Coordinating plans is often expected to be simple, but in practice it can become time consuming and unreliable especially when availability is unclear and plans rely on repeated messaging. Oakley's work highlights student loneliness as a recognised issue within higher education [1], while Richardson, Elliott & Roberts report an association between loneliness and student mental health [2], which shows that it is important to consider how everyday barriers to meeting in person might reduce opportunities for social connection.

This project will end with a complete, functional, and testable iOS solution that's centred on an automated group availability workflow that helps friends quickly identify suitable times to meet, reducing the "back and forth" that is typically involved in organising plans. Ease of use is prioritised throughout, while privacy and comfort are treated as core requirements so that any sharing of availability remains intentional, clear, and user controlled.

The project is a sufficient computer science challenge for me because it combines multiple skillsets into one coherent system. On the client side, it requires mobile software engineering in Swift/SwiftUI (multi-screen navigation, state management and app architecture). It also involves backend integration and data modelling using Firebase for authentication, storing availability and group data and synchronising updates in real time. The automated scheduling feature introduces algorithmic problem solving by collecting user inputs, computing overlapping time windows and presenting ranked suggestions clearly. Finally, the work will be evaluated with the target audience, requiring structured testing and iterative refinement based on findings.

---

## Aim and Objectives

### Aims

- Deliver a functional iOS prototype that implements my designed automated group availability approach to reduce the "back and forth" of organising student meet ups.
- Evaluate the prototype with university students to determine whether the solution is usable, privacy acceptable and genuinely reduces coordination effort compared to current group chat planning.

### Objectives

1. Build the app in Xcode using Swift & SwiftUI, using a clear architecture with reusable components and consistent navigation.
2. Implement user onboarding: sign up / log in, profile basics and a settings area (e.g. add friends, log out, delete account).
3. Implement friend & group management so users can create a group, view members and manage group participation.
4. Implement the core availability workflow:
   - A shared availability / group calendar view that highlights overlapping free time.
   - A polling style scheduling flow to propose options and collect responses quickly.
   - A feature to signal immediate availability to a group.
5. Develop the scheduling logic to:
   - Convert user inputs into availability blocks.
   - Compute overlaps.
   - Highlight/rank the best meeting options clearly.
6. Implement notifications & live updates so users see progress without manually checking.
7. Build response visibility features (e.g. response/status indicators, poll history/progress visibility).
8. Include privacy controls that keep sharing intentional.
9. Integrate a Firebase backend:
   - Authentication for accounts.
   - Firestore data model for users, friends, groups, polls and availability.
   - Real time syncing for group updates.
   - Security rules to enforce access control and privacy boundaries.
10. Run structured testing with the target audience:
    - Task based usability sessions.
    - Post task Likert questionnaire on ease, clarity and coordination improvement.
    - Basic metrics (task success, time on task, errors/hesitations).
    - Qualitative feedback (think-aloud and open-ended questions).
11. Iterate the prototype based on test findings.

---

## Feasibility

This project is feasible within the available time and resources because the solution can be delivered as a focused MVP iOS prototype with a clearly defined concept and screen flow. The intended feature set (authentication, friends/groups, availability input, overlap suggestions, and basic notifications) aligns well with standard iOS patterns which reduces any ambiguity during implementation.

From a technical perspective, the chosen stack is appropriate and well supported. SwiftUI provides the UI and state driven interaction needed for multi screen flows (login/signup, home, groups, availability views, settings). On the other hand, Firebase can handle authentication and real time data synchronisation for users, groups and availability without requiring a custom server. The scheduling feature is also realistic to build because it's basically a clear set of steps: each person enters when they're free, the app compares everyone's free times, finds the time slots that overlap, and then suggests the best options (for example, the slots that fit the most people or give the longest shared window). This is challenging enough to be interesting, but still straightforward to implement and test.

The project is also practical in terms of tooling and access. Development will be completed in Xcode on my macOS with testing on an iPhone (simulator and physical device). Firebase offers a free tier for prototyping and the dataset size that I'll need (student groups and availability blocks) is small, so performance requirements are manageable.

Evaluation is achievable using a small sample of university students recruited through course networks/social channels. Usability testing can be conducted with task based sessions and short questionnaires. Key risks include scope creep, real time sync edge cases and privacy/security rules. These will be mitigated by keeping a strict MVP scope, implementing Firebase Security rules early and testing incrementally with realistic scenarios.

---

## Work Plan

My timetable splits the project into a structured 12 week plan, with clear milestones for implementation and evaluation to ensure steady progress throughout the semester. I will track and manage all tasks using a Jira board (with a timeline/Gantt view), which allows me to break the work into major deliverables, set start and end dates, and monitor progress visually as tasks move through different stages. Using Jira also helps me stay organised week to week, identify what I should be working on next, and spot any areas where tasks begin to slip so I can adjust early. To avoid becoming overwhelmed near the deadline, I have intentionally planned to complete the main development work around a week and a half before the final submission date. This creates a buffer for usability testing, iterations based on feedback, and producing the final write up and supporting evidence (screenshots, results, and evaluation notes) without having to rush both the build and the report at the same time.

### Timetable

*(Add your timetable here.)*

### Gantt Chart

*(Add your Gantt chart here.)*

---

## References

[1] Oakley, L. (2020). *Exploring Student Loneliness in Higher Education: A Discursive Psychology Approach*. Palgrave Macmillan.

[2] Richardson, T., Elliott, P., & Roberts, R. (2017). Relationship between loneliness and mental health in students. *Journal of Public Mental Health*.
