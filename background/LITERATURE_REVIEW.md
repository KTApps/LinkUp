# Literature Review

## What is already known about the problem?

Coordinating social plans in a group is rarely as simple as 'find a time everyone is free'. A diary study by Schuler et al. (2014) shows that everyday social coordination is typically managed through open channel communication (e.g. texting, calls and email) because it feels flexible and natural for negotiating plans. However, this often leads to 'conversational overload' and a disparity of work, where one or two people take on the burden of chasing replies, summarising decisions and keeping everyone aligned as details change over time (Schuler et al. 2014). This highlights that the main challenge is not only identifying a suitable slot, but sustaining progress toward a shared decision across fragmented conversations and uneven participation.

Scheduling also behaves like a group decision making process rather than a purely logistical calculation. An analysis from Reinecke et al. (2013) demonstrates this using a large scale dataset from online scheduling polls (In tools such as Doodle), where one person suggests several candidate time options and the group responds by indicating which options they can make. Their analysis shows that how people respond (including response timing and which options they mark as possible) reflects social norms and expectations around cooperation and commitment, not just objective availability (Reinecke et al. 2013). This supports the idea that 'friction' often comes from human dynamics such as hesitation, preference signalling and differing standards of commitment, rather than simply missing calendar information.

A further complication is that availability is not neutral data. A qualitative study by Palen (1999) explains how shared calendars can expose patterns of time use that invite inference and 'peer judgment,' making people cautious about what they reveal. Even when visibility improves coordination, individuals may still limit disclosure or use partial sharing strategies because they want control over what others can infer from their schedules (Palen, 1999).

When combined, the literature frames group scheduling as ongoing coordination work beyond slot finding, shaped by social decision norms and constrained by privacy/comforts.

---

## What solutions have been tried and how well did they work?

A common approach to group scheduling is poll based coordination, where one person proposes a shortlist of candidate times and invitees indicate which options they can attend. Doodle is a well known example where participants respond to proposed slots by marking 'yes', 'no' or an 'if need be' option that captures secondary flexibility. This structure can reduce the messiness of open ended chat because it turns replies into a visible table of options. However, it still depends on the organiser selecting 'good' candidate times in advance and on participants actually responding. If responses are late or incomplete, the poll does not resolve the underlying coordination problem, it just records whatever responses you managed to get.

Another widely used pattern is the availability grid, where participants paint their free time on a shared timetable and overlaps become visually obvious. When2Meet is a classic example and is designed to be quick to use, with minimal setup. It is web based and can be used without creating an account or installing software, which reduces initial friction. This can work well for quickly discovering overlapping windows, especially for larger groups. But grid tools often stop at 'here are the overlaps,' leaving the group to still negotiate the final choice, confirm it and keep everyone updated, so decision making frequently falls back to group chats in other platforms.

A more persistent solution is the shared group calendar, where the coordination space is ongoing rather than event by event. TimeTree explicitly positions itself as group based calendar sharing (multiple calendars for different groups) and it includes features intended to keep planning inside the calendar itself, such as memos/to-dos and chat within events. These tools can be effective once a group commits to using them, because plans and updates stay in one place over time. The trade off is that they typically require habit change (people must adopt and maintain the shared calendar) and they raise sharing expectations, meaning groups need enough consistent usage for the calendar to become trustworthy.

Mainstream calendar platforms also offer 'find a time' workflows that show invitees' availability while you're creating an event. In Google Calendar, organisers can use 'Find a time' to view when invited guests can attend, but only if those guests have shared their calendars. Outlook provides similar functionality through Scheduling Assistant, showing free/busy availability to help identify times that work for everyone. These are powerful when calendars are accurate and sharing is in place, but that assumption often breaks down for informal social groups where people may not maintain calendars or may not want to share availability beyond close contacts.

Finally, event invite apps like Partiful target a related but slightly different stage of the problem. They make it easy to create an invite page, collect RSVPs and send updates to guests. They can reduce friction after a time is chosen, but they do not solve the issue of finding a mutually workable time.

Overall, these tools show clear progress. For example: polls structure responses, grids reveal overlaps, shared calendars centralise plans and 'find a time' features leverage free/busy data. But they also surface constraints such as response friction, adoption/habit change and privacy/comfort around sharing time.

---

## What design constraints matter from literature?

Designing group scheduling tools is constrained in 3 areas: adoption, privacy and social pressure. On adoption, a Computer Supported Cooperative Work (CSCW) analysis by Grudin (1988) argues that many collaborative systems fail because there is often a 'disparity' between who benefits and who must do extra work to keep the system running. He illustrates this with automatic meeting scheduling. If a system relies on everyone keeping their calendars up to date, it stops working as soon as people fail to maintain them. Without broad participation, the scheduler becomes ineffective (Grudin, 1988). This implies that even a well designed feature won't help if it requires new habits that only some people follow.

A second constraint is that privacy cannot be treated as a one time setting. A conceptual analysis by Palen and Dourish (2003) describe privacy as a dynamic, dialectic boundary regulation process rather than something you 'solve' by fixed rules. They explicitly note that privacy management is continual boundary management, where boundaries 'move dynamically as the context changes,' and technology can destabilise the usual ways people judge what is appropriate to share (Palen and Dourish, 2003). In everyday coordination, this means people may share differently depending on who is asking, what the event is and what their availability might imply.

Finally, the literature warns that making availability highly visible can create pressure. Palen's (1999) qualitative study shows that open groupware calendars can expose time use in ways that invite 'peer judgment about time allocation' and inference about workload, so users often try to manage privacy with mechanisms like access settings (e.g. showing only free/busy) or more strategic calendar entries. A Human Computer Interaction (HCI) paper by Erickson and Kellogg (2000) generalise this social effect. They argue there is a 'vital tension between privacy and visibility,' because what people do changes when they know others are watching, as visibility increases awareness and accountability.

---

## What gap remains in research/tools?

A clear gap in current tools is that they often support only one part of group scheduling, rather than the full journey from an uncertain conversation to a confirmed plan. Availability grids can make overlaps visible and polls can collect preferences, but neither necessarily helps a group move from 'we should catch up' to 'this is the agreed time' without returning to messaging to negotiate, chase replies and confirm the outcome. This matters because social scheduling is not just slot finding, but it involves ongoing coordination work and uneven participation, where someone typically has to keep the process moving (Schuler et al. 2014).

A second gap is the tension between coordination and privacy. Many existing approaches implicitly push groups toward either binary availability ('I can / can't') or broad calendar exposure (shared calendars or free/busy access). However, the literature suggests that privacy around time is socially sensitive and context dependent. Palen (1999) shows that calendars can invite 'peer judgment' and inference about time allocation, which helps explain why people may be reluctant to make their schedules legible to others. Palen and Dourish (2003) further argue that privacy is a dynamic boundary management process rather than a fixed setting, meaning that what people consider acceptable to share changes with the audience and situation. When tools do not reflect this nuance, by offering only coarse sharing choices or assuming transparency, they risk discouraging participation or pushing users toward defensive behaviours.

A third gap is that many tools under address the 'soft' social reality of group decision making. Large scale evidence from online scheduling polls shows that response patterns and the path to consensus are shaped by social norms around cooperation and commitment, not just practical availability (Reinecke et al. 2013). People may delay responding, avoid early commitment, or signal flexibility strategically. If participating feels effortful or socially risky, groups revert to the familiar back and forth of chat.

Against this background, the unique angle of my approach is an end to end workflow designed for informal friend groups which combines overlapping timetable calculations, structured decision support (to turn options into agreement) and progress visibility (so it's clear who has contributed and what remains), while supporting intentional, low detail sharing to reduce privacy discomfort. This responds to the adoption and participation problems highlighted in the CSCW research (Grudin, 1988) and to the privacy/visibility tensions identified in studies of calendars and social translucence (Palen, 1999; Erickson and Kellogg, 2000).

---

## How does that gap justify an MVP + evaluation plan?

The gaps identified in existing tools justify an MVP that prioritises an end to end coordination loop rather than a single feature. Because social scheduling involves ongoing coordination work that is often unevenly distributed (Schuler et al. 2014; Grudin, 1988), the MVP should focus on a workflow where users enter availability, the system surfaces the best overlaps, the group can vote or confirm a small set of workable choices and the outcome is locked in and visible so it does not rely on memory or repeated chat follow ups. This directly addresses the practical reality that tools fail when they require heavy manual chasing or assume everyone will behave consistently (Grudin, 1988).

Privacy by design should be treated as a core MVP requirement rather than an optional enhancement. Palen and Dourish (2003) frame privacy as ongoing boundary management, while Palen (1999) shows how calendar visibility can lead to peer judgment and inference; Erickson and Kellogg (2000) further describe the tension that arises when visibility increases accountability. Together, these findings support availability sharing that is intentional and low detail by default, with granularity and audience control.

Evaluation should then test whether the MVP improves group scheduling in the ways existing tools do not. First, measure coordination effort: compared with poll only or grid only approaches, can groups reach a decision with fewer steps and less organiser burden (Schuler et al. 2014; Grudin, 1988)? Second, assess comfort and privacy acceptance: do users feel they can take part without oversharing and remain in control of what others can infer (Palen, 1999; Palen and Dourish, 2003)? Third, test decision clarity and reliability: do users understand the recommended 'best options,' perceive them as fair and reach a confirmed plan more reliably, given that commitment is shaped by norms and expectations rather than pure availability (Reinecke et al. 2013).

---

## References

Palen, L. (1999) 'Social, Individual & Technological Issues for Groupware Calendar Systems', *Proceedings of the ACM CHI '99 Conference on Human Factors in Computing Systems (CHI '99)*, pp. 17–24.

Reinecke, K. Nguyen, M.K. Bernstein, A. Näf, M. and Gajos, K.Z. (2013) 'Doodle around the world: Online scheduling behavior reflects cultural differences in time perception and group decision-making', *Proceedings of the 2013 Conference on Computer Supported Cooperative Work (CSCW '13)*, pp. 45–54.

Schuler, R.P. Grandhi, S.A. Mayer, J.M. Ricken, S.T. and Jones, Q. (2014) 'The Doing of Doing Stuff: Understanding the Coordination of Social Group-Activities', *Proceedings of the SIGCHI Conference on Human Factors in Computing Systems (CHI '14)*, pp. 119–128.

Grudin, J. (1988) 'Why CSCW Applications Fail: Problems in the Design and Evaluation of Organizational Interfaces', *Proceedings of CSCW '88*, pp. 85–93.

Palen, L. and Dourish, P. (2003) 'Unpacking 'Privacy' for a Networked World', *Proceedings of CHI '03*, pp. 129–136.

Erickson, T. and Kellogg, W.A. (2000) 'Social Translucence: An Approach to Designing Systems that Support Social Processes', *ACM TOCHI*, 7(1), pp. 59–83.
