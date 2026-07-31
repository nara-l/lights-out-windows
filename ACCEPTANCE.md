# Acceptance and verification

This file distinguishes code existence from a working bedtime boundary.

| Capability | Acceptance criterion | Status | Verification and evidence | Remaining blocker |
| --- | --- | --- | --- | --- |
| Schedule calculation | Weekday lunch countdown at 11:30 AM, hibernate from 11:45 AM to 1:30 PM; Sunday-Thursday night countdown at 9:30 PM, hibernate from 9:59 PM to 6:00 AM | Operationally verified | Sixteen boundary cases passed on 2026-07-30, including lunch start/end and weekend exclusions | None for local logic |
| Countdown | Centered, topmost countdown becomes amber and then red | Operationally verified | Safe 15-second preview ran successfully on 2026-07-30 | None for local preview |
| Hibernation | Real scheduled invocation preserves the Windows session | Implemented | Must exercise hibernate and wake on this laptop | Operational run pending |
| Recurring trigger | Countdown runs at 11:30 AM on weekdays and 9:30 PM Sunday-Thursday; guards repeat every five minutes only inside the lunch and night boundaries | Integrated | Two tasks reinstalled for `LAPTOP-AA2BL28E\Lawrence.work`; live inspection confirmed 11:45 AM/PT1H45M and 9:59 PM/PT8H1M guards, both at PT5M intervals | Observe the first real lunch countdown and hibernate/wake cycle |
| Boundary guard | Use during blocked hours causes another hibernate request within five minutes | Integrated | Blocked-time branch returned `Hibernate suppressed by -NoHibernate` | Real blocked-hours hibernate/wake run pending |
| Failure behavior | Task Scheduler records failures and retries at the next five-minute guard interval | Implemented | Induce a safe failure and inspect task result/history | Operational test pending |
| Removal | Both scheduled tasks are removed without touching personal work | Operationally verified | Removed both tasks, confirmed zero remained, and reinstalled both on 2026-07-30 | None |
| System runtime overview | README explains both runtime boundaries and the separate Family Safety boundary without requiring the reader to open the code | Operationally verified | Public README and SVG at commit `eeb3fbc` show shared warning, hibernate, and guard behavior for lunch and night | None |
| Hard account lock | Everyday account cannot grant itself more time or disable the boundary | Not integrated | Microsoft Family Safety organizer observes a blocked sign-in | Trusted organizer configuration required |

The project is not **complete** until the real trigger, hibernate/wake cycle,
scheduled retry, removal/reinstall cycle, and Family Safety lock are all
operationally verified.
