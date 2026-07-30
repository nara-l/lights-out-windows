# Acceptance and verification

This file distinguishes code existence from a working bedtime boundary.

| Capability | Acceptance criterion | Status | Verification and evidence | Remaining blocker |
| --- | --- | --- | --- | --- |
| Schedule calculation | Sunday-Thursday countdown at 9:30 PM, hibernate at 9:59 PM, reopen at 6:00 AM; weekends remain open | Operationally verified | Nine boundary cases passed on 2026-07-30 | None for local logic |
| Countdown | Centered, topmost countdown becomes amber and then red | Operationally verified | Safe 15-second preview ran successfully on 2026-07-30 | None for local preview |
| Hibernation | Real scheduled invocation preserves the Windows session | Implemented | Must exercise hibernate and wake on this laptop | Operational run pending |
| Recurring trigger | Countdown runs once at 9:30 PM; the windowless guard runs every five minutes only from 9:59 PM to 6:00 AM | Integrated | Both tasks installed for `LAPTOP-AA2BL28E\Lawrence.work`; guard trigger reports a weekly 9:59 PM start, five-minute interval, and 8-hour-1-minute duration | Tonight's countdown observation pending |
| Boundary guard | Use during blocked hours causes another hibernate request within five minutes | Integrated | Blocked-time branch returned `Hibernate suppressed by -NoHibernate` | Real blocked-hours hibernate/wake run pending |
| Failure behavior | Task Scheduler records failures and retries at the next five-minute guard interval | Implemented | Induce a safe failure and inspect task result/history | Operational test pending |
| Removal | Both scheduled tasks are removed without touching personal work | Operationally verified | Removed both tasks, confirmed zero remained, and reinstalled both on 2026-07-30 | None |
| Architecture map | Repository includes a numbered visual map of triggers, runtime components, enforcement boundaries, and evidence | Operationally verified | `boards/architecture.tldr` contains 11 components and 12 connections; generated summary confirmed 48 shapes | None |
| Hard account lock | Everyday account cannot grant itself more time or disable the boundary | Not integrated | Microsoft Family Safety organizer observes a blocked sign-in | Trusted organizer configuration required |

The project is not **complete** until the real trigger, hibernate/wake cycle,
scheduled retry, removal/reinstall cycle, and Family Safety lock are all
operationally verified.
