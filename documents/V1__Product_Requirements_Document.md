# Product Requirements Document - Job Application Tracker
>**Project:** Application Tracker,
**Owners:** Eduard (repo owner) & Adam,
**Last Updated:** 2026-09-25,
**Status:** Draft v1.0
---
# 1. Overview
Web Application that helps track recent job applications from first interest to final outcome. It brings together everything during a job search: applications, pipeline stages, contacts, interactions, notes, key dates, reminders, and the exact CV and Cover-Letter versions sent to each employer.

The first release (V1) would be a fully manual CRUD application. AI Assistance (V2) will build on top of that model. Inbox sync (V3) Will build on top of that as well.

# 2. Problem Statement
I often send dozens of applications in parallel, each with different stages, deadlines, recruiters and document versions. I usually track this in a spreadsheet, in my inbox and from memory. As a result:
- deadlines and follow-ups missed
- lose track of what was communicated and which CV version went to which employer
- recruiter and interviewer contacts end up scattered across LinkedIn, Email and Notes
- no clear picture of how their pipeline is performning (for example, where applications stall)

# 3. Target Users
| Persona | Description | Primary Needs|
|---|---|---|
|Recent Graduates | 0-2 years post-graduation, applying to grad schemes and junior roles, often 20-100+ applications per cycle| Fast capture, clear status overview, never missing a deadline, knowing what was sent where |
| Careers switcher / student | Similar volume & Workflow | Same as above

The product is B2C, and users sign up themselves. There is no admin persona in v1 beyond the developers.
# 4. Goals & Success Criteria

|#|Goal|Measure of Success|
|---|---|---|
|G1|Users can see all their applications at a glance| Dashboard shows count by stage, upcoming dates, reminders and recent activity|
|G2| Adding an application is fast| A new application can be added in under 60 seconds with the required fields|
|G3|Communications are tracked per application| Interactions (including manually logged emails) are visible on both the application and the contact|
|G4|The project works as a portfolio piece| Publicly reachable deplyoment, open-source repo,  CI with end-to-end tests, documented architecture|

# 5. Scope
## 5.1 Release Plan
|Release | Theme | Contents|
|---|---|---|
|v1.0 (MVP)| Manual Tracking | `V1__Functional_Requirements.md`|
|v2.0 | AI integration | tbd |
|v3.0 | Email integration | tbd|

## 5.2 Explicitly out of scope for v1.0
- Any AI features
- Inbox sync
- Prefilling an application from a job URL
- Bulk actions
- Customisable pipeline stages
- Native mobile apps
- Teams, sharing or collaboration between users
- Payments or subscriptions

# 6. Functional Requirements
Priority: **M** = Must, **S** = Should, **C** = Could.
## 6.1 Accounts & Authentication
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|AUTH-1|Users can register with email & password|M
|AUTH-2|Users can sign in & sign out; sessions persist via refresh tokens|M
|AUTH-3|Users can reset a forgotten password by email|S
|AUTH-4|Users must verify their email address before first sign-in|S
|AUTH-5|Users can delete their account and all associated data files|M
|AUTH-6|Users can export all of their data as CSV|M
## 6.2 Applications
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|APP-1 | Create an application with: **company** (required), **role title** (required), job URL, location, salary range (min/max/currency), source, date applied, deadline| M |
|APP-2 | Edit and view an application on a detail page with tabs or sections: Overview, Contacts, Interactions, Notes, Dates, Documents, Timeline|M |
|APP-3 |Each application has exactly one current stage from a fixed list (S6.3) |M |
|APP-4 |Changing stage records a timestamped entry in the stage history (timeline)|M |
|APP-5 |Re-applying: creating an application for a company and role that already exists shows a non-blocking warning linking to the previous application(s); both are kept as separate records |M |
|APP-6 |Archive: users can archive or unarchive an application. Archived applications are hidden from default views and still count in statistics |M |
|APP-7 |Delete: users can permanently delete an application after confirmation. This cascades to its notes, dates, reminders and links, but not to shared contacts or documents |M |
|APP-8 |Applications list (table view) with sorting, filtering (stage, source, archived, date ranges) and search (company or role) |M |
|APP-9 |Kanban board with a column per stage; dragging a card changes its stage (APP-4 applies) |M |
|APP-10 |Export the applications list to CSV, respecting current filters|M |
## 6.3 Pipeline Stages
```Wishlist -> Applied -> Pre-Screening -> Recruiter-Call -> Online - Assessment -> Interviewing -> Asessment-Centre -> Final-Stage -> Offer -> Rejected -> Withdrawn -> Lapsed``` 

The Terminal stages are `Accepted`, `Rejected`, `Withdrawn`, `Lapsed`. `Rejected`, `Withdrawn`, `Lapsed` can be reached from any non-terminal stage. Any stage transition is allowed, including moving backwards to correct mistakes, and every transition is logged.

## 6.4 Companies
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|CO-1| Companies are a lightweight per-user entity (name, website, notes), created inline when adding an application or contact | M|
|CO-2| A company page lists its applications and contacts| S |
## 6.5 Contact & Interactions
|**ID**|**Requirement**|**Priority**|
|---|---|---|
| CON-1 | Create contacts with name (required), job title, company, email, phone, LinkedIn URL and notes|M
| CON-2 | A contact can be linked to multiple applications, with a role per link (e.g. Recruiter, Hiring Manager, Interviewer, Referrer)|M
| CON-3 | Log interactions: type (Email, Call, LinkedIn, Meeting, Other), direction (Inbound/Outbound), date/time, subject, body. An interaction links to a contact and/or an application |M
| CON-4 | A contact's interaction log shows all their interactions across applications |M
| CON-5 | An application's Interactions tab shows all interactions linked to it, including those logged from a contact|M
| CON-6 | Manually logged emails are Email-type interactions. In v3.0, synced emails use the same model|M

## 6.6 Notes, Important Dates & Reminders
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|NOTE-1 |Add, edit and delete notes on an application (Markdown supported)|M|
|DATE-2 |Add important dates to an application: title, type (Interview, Assessment, Deadline, Offer expiry, Other), date/time, and an optional location or meeting link|M|
|REM-1 |Create manual reminders (title, due date/time, optional application) |M|
|REM-2 |Automatic reminder when an application deadline or important date is 3 days away |M|
|REM-3 |Automatic "follow up?" reminder when a non-terminal application has had no stage change, interaction or note for 14 days|M|
|REM-4 | Reminders show in-app (dashboard panel and a bell/badge). Users can mark them done, snooze them (1 day, 3 days or 1 week) or dismiss them|M|
|REM-5 | Automatic reminders are never duplicated for the same trigger|M|
## 6.7 Documents
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|DOC-1 | Upload documents (PDF or DOCX, ≤ 10 MB) to a personal document library with a name and type (CV, Cover Letter, Portfolio, Transcript, Other)| M|
|DOC-2 | Documents are versioned: uploading a new version keeps earlier versions (v1, v2, …)| M|
|DOC-3 |An application links to specific document versions, so the user can see exactly what was sent | M|
|DOC-4 |A document's page shows which applications used each version | M|
|DOC-5 |Download or preview a document version (PDFs preview in the browser) | S|
## 6.8 Dashboard
|**ID**|**Requirement**|**Priority**|
|---|---|---|
|DASH-1 |Counts by stage (active applications, excluding archived by default) | M|
|DASH-2 |Upcoming dates and deadlines (next 14 days) | M|
|DASH-3 |Pending reminders | M|
|DASH-4 | Recent activity feed (applications added, stage changes, notes, interactions)| M|
|DASH-5 | Compact spreadsheet-style table of active applications, editable inline for stage and key dates | S|
|DASH-6 | Sankey diagram of stage flow, built from stage history| C `v1.1`|


# 7. Key Screens
1. **Sign up** / **Sign in** / **Reset password** / **Verify email**
2. **Dashboard:** stage counts, upcoming dates, reminders, activity feed, compact table, and optionally the Sankey diagram
3. **Applications:** a table view and a Kanban view, with a toggle to switch between them; filters, search and export
4. **Application detail:** Overview · Contacts · Interactions · Notes · Dates · Documents · Timeline
5. **Add/Edit application:** a form, which can be a modal or a page
6. **Contacts list** and **Contact detail** (profile, linked applications, interaction log)
Documents library and Document detail (versions, usage)
7. **Reminders** panel or page
8. **Settings:** profile, password, data export, delete account

# 8. Core User Journeys 
|#|Theme | Contents|
|---|---|---|
|**J1**|**Add an application**| Click "New application", then type a company name. The suer iether picks an existing company or creates one inline. They fill in the role and optional fields and pick a stage (default: `Applied` if a date applied is set, otherwise `Wishlist`). They can optionally attach documents. On save, the stage history get its first entry and deadline reminders are sheduled.
|**J2**|**Progress through the pipeline**|Drag a card on the kanban, or in table view change the stage there, or in detail page change it there. This records a stage-history entry, updates the activity feed and resets teh 14-day inactivity clock|
|**J3**|**Log a recruiter email**| Either open the application and choose Interactions, then "Log email", or open the contact and do the same there. Pick the contact and/or application, then fill in the subject, body, date and direction. The interaction appears on both the contact and the application.|
|**J4**|**Send a tailoured CV**| Upload "CV – Software" v3 in the Documents library, then open the application and link v3 under Documents. Later, the document's page shows that v3 went to this company.| 
|**J5**|**Follow up**| The dashboard shows an automatic reminder: "No update on Acme – Graduate Engineer for 14 days". The user logs a follow-up email (J3) and marks the reminder done.|
|**J6**| **Re-apply** | The user adds a new application for the same company and role. A warning appears with a link to the previous application (for example, rejected in March). The new record is created separately.|
|**J7** | **Clean-up** | Archive finished applications to declutter the default views, or delete them permanently after confirmation. |

# 9. Edge Cases & Rules
- Duplicate detection (APP-5) matches on company and a case-insensitive role title. It warns but never blocks.
- Shared contacts: deleting an application removes the link to a contact, not the contact itself. Deleting a contact removes its links, but its interactions stay on the application with a "(deleted contact)" label.
- Documents in use: deleting a document version that is linked to applications requires explicit confirmation listing the affected applications.
- Terminal stages: reaching Accepted, Rejected or Withdrawn cancels that application's pending automatic reminders.
- Archived applications: these never generate automatic reminders.
- Time zones: dates are stored in UTC and shown in the user's browser time zone. Deadlines without a time are treated as end of day, local time.
- Salary: stored as integers (min/max) with an ISO currency code, defaulting to GBP. Either value is optional.
- Validation: job URLs must be valid http(s) URLs. File type is checked from the file's content, not just its extension.
- Empty states: every list has a helpful empty state with a primary call to action.

# 10. Non Functional Requirements
| Area | Requirement |
|---|---|
| Security |HTTPS everywhere. Passwords hashed with ASP.NET Identity defaults. Every query is scoped to the authenticated user, so there's no cross-user data access. Rate limiting on auth endpoints |
| Privacy (UK GDPR)|Users own their data and the contact details they store about third parties. Full export (AUTH-6) and deletion (AUTH-5). A privacy notice is published before public launch. No third-party tracking in v1 |
| Performance| p95 API latency < 300 ms for list and detail endpoints at 1,000 applications per user. Dashboard loads in < 2 s|
|Availability |Best effort on the homelab. Health checks, automatic container restarts, nightly backups (see architecture doc) |
| Accessibility|WCAG 2.1 AA target: keyboard-operable Kanban board (with drag-and-drop alternatives) and semantic, labelled forms |
| Responsiveness| Usable from 375 px wide upward. On mobile, the Kanban board scrolls horizontally|
| Browswer Support | Latest version of Chrome, Firefox, Safari & Edge|

# 11. Open Questions tbd
1. Final Product name & domain
2. Email verification at launch or not?
3. Sankey Diagram in `v1.0` or `v1.1`?
4. How long to keep data for inactive accounts?
