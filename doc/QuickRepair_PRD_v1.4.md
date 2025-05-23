# Product Requirement Document (PRD)
**Application:** QuickRepair  
**Date:** 2025-05-5 
**Author:** rasyaravy, Technical Writer  

---

## 1. Background & Objective
**QuickRepair** is a Flutter-based mobile application designed to simplify and accelerate the reporting and remediation of facility damage in educational institutions. It addresses common pain points—slow response times, fragmented communication, and lack of visibility—by providing an end-to-end solution: instant photo-and-GPS reporting, real-time status tracking, chat, and centralized admin management.

**Objective:** Deliver a scalable, secure, and user-friendly system that reduces issue-to-assignment time below 2 hours, increases resolution efficiency by 50% within six months, and achieves an NPS >75 among internal users.

## 2. Stakeholders & Roles
| Role                 | Responsibility                                           | Interest                                     |
|----------------------|----------------------------------------------------------|----------------------------------------------|
| Product Sponsor      | Project funding & high-level approvals                   | ROI, strategic alignment                     |
| Product Manager      | Prioritization, roadmap, stakeholder liaison             | On-time delivery, feature adoption           |
| Technical Writer     | PRD maintenance, API documentation, style consistency     | Accuracy, completeness                        |
| CTO / Architect      | System architecture, technology evaluation               | Scalability, maintainability                  |
| Flutter Developer    | Front-end implementation                                 | Clarity of requirements, UI/UX fidelity       |
| Backend Engineer     | Supabase schema, API, real-time engine                   | Data consistency, performance                 |
| UI/UX Designer       | Wireframes, style guide, onboarding flows                | Brand consistency, usability                  |
| QA Engineer          | Test planning, test cases, automation                    | Quality, reliability                          |
| Centralized Admin    | Manage reports, assign technicians, monitor KPIs         | Ease of use, dashboard insights               |
| Technician           | Receive assignments, update status, communicate          | Clear instructions, mobile accessibility      |
| Reporter (User)      | Report damage, monitor progress, chat with technician    | Simplicity, feedback loops                    |

## 3. Assumptions & Constraints
- **Assumptions:**  
  - Users have stable internet connectivity (min. 4G/LTE).  
  - GPS permissions and location services enabled.  
  - Single centralized admin manages all mobile reports via a web-based admin portal.  
  - Stakeholders approve timeline and budget.  
- **Constraints:**  
  - Supabase free tier until budget approval.  
  - Performance optimization required for low-end devices.  
  - Apple/Google developer accounts must be provisioned by June 2025.

## 4. Glossary
- **Reporter:** End user submitting damage reports.  
- **Admin:** Centralized authority managing and assigning reports.  
- **Technician:** Individual assigned to fix reported issues.  
- **NPS:** Net Promoter Score, measuring user satisfaction.  
- **DAU/MAU:** Daily/Monthly Active Users ratio.  
- **FCM:** Firebase Cloud Messaging (Android).  
- **APNs:** Apple Push Notification service (iOS).  
- **WCAG AA:** Web Content Accessibility Guidelines, level AA.

## 5. Core Features & User Stories
### 5.1 Quick Reporting
- **User Story:** Reporter uploads photo + GPS location in < 10 seconds.  
- **Detail:** Integrated camera/gallery API; auto-fill coordinates.  
- **Acceptance:** Photo compressed ≤ 1 MB; GPS accuracy within 10 m.

### 5.2 Real-Time Chat & History
- **User Story:** Reporter ↔ Technician exchange messages within each report.  
- **Detail:** Supabase Realtime for bi-directional chat; reporter can edit/delete own messages.  
- **Acceptance:** Message sync latency < 1 s; persistence of history with timestamps.

### 5.3 Status Tracking & Push Notifications
- **User Story:** Reporter receives push notifications for any status change.  
- **Detail:** Use FCM & APNs; in-app badge with update count.  
- **Acceptance:** Notification delivery within 5 s; tapping leads to detailed report view.

### 5.4 Admin Dashboard
- **User Story:** Admin views aggregated metrics and assigns technicians.  
- **Detail:** Interactive charts (bar, pie), data table with search & filters; assign/reassign action.  
- **Acceptance:** Dashboard refresh < 2 s; assignment triggers immediate reporter notification.

### 5.5 Onboarding Flow
- **User Story:** New user guided through three introductory screens.  
- **Detail:** Illustrations + concise copy for core features.  
- **Acceptance:** Swipe navigation; skip option; shown only once per user.

## 6. Functional Requirements
| ID      | Requirement                                                              | Priority |
|---------|---------------------------------------------------------------------------|----------|
| FR-01   | Authentication & Authorization via Supabase (SSO/email)                  | High     |
| FR-02   | Photo capture/upload & preview                                            | High     |
| FR-03   | Automatic GPS location capture & map display                              | High     |
| FR-04   | Create, Read, Update (status), Delete reports                             | High     |
| FR-05   | Real-time chat & message management                                       | Medium   |
| FR-06   | Push notifications for status updates                                      | High     |
| FR-07   | Admin dashboard (charts, tables, search, filters)                         | High     |
| FR-08   | Technician assignment & reassignment                                       | High     |
| FR-09   | Data export (CSV, PDF)                                                     | Low      |
| FR-10   | Dark & Light mode support                                                  | Medium   |
| FR-11   | Onboarding screens (3 pages)                                               | Medium   |
| FR-12   | English language support                                                   | High     |
| FR-13   | Error & Empty states handling                                              | Medium   |

## 7. Non-Functional Requirements
- **Performance:** ≤ 2 s screen load on 4G; chat latency ≤ 1 s.  
- **Security:** HTTPS, Supabase row-level security, encrypted at-rest storage.  
- **Scalability:** Support 10k reports/month; horizontal scaling ready.  
- **Reliability:** 99.5% uptime; automated health checks.  
- **Accessibility:** WCAG AA compliance; screen reader accessible.  
- **Maintainability:** Modular codebase, documented APIs (Dartdoc, Swagger), CI checks.

## 8. Design Guidelines
- **Color Palette:** Primary Orange (#FF9800) & Accent Blue (#2196F3).  
- **Iconography:** Flat modern icons (Material Icons / Feather).  
- **Typography:** Roboto family (Regular, Medium, Bold).  
- **Spacing & Layout:** 8dp grid, padding ≥ 16dp, 2xl corner radius.  
- **Navigation Patterns:** Bottom nav for reporters; sidebar/hamburger for admin.  
- **Responsiveness:** Adapt layouts for screen widths 320–720dp; scalable font sizes.  
- **Illustrations:** Consistent style for onboarding, error/empty states.

## 9. UI/UX & Additional Flows
- **Scope:** Initial release focuses exclusively on the mobile application frontend; the centralized admin portal will be implemented as a responsive web-based dashboard in a subsequent phase.  
- **Language:** English for all UI text and notifications.  
- **Theme Support:** Default Light mode; optional Dark mode with inverted palette.  
- **Error States:** Custom UI for offline, permission denial, upload failures.  
- **Empty States:** Engaging illustrations + CTAs (e.g., “Create your first report”).

## 10. Technology Stack & Architecture
- **Front-end:** Flutter 3.x (Dart), Provider/BLoC for state management.  
- **Back-end:** Supabase (Postgres, Realtime, Auth, Storage).  
- **Mapping:** Google Maps SDK (Flutter plugin).  
- **Notifications:** FCM & APNs via Supabase Edge Functions.  
- **CI/CD:** GitHub Actions; distribute via TestFlight & Play Store Beta.  
- **Monitoring & Analytics:** Sentry for crash reporting; Firebase Analytics for event tracking; Supabase logs.

## 11. Data Model & API Endpoints
- **Data Model:**  
  - `users`, `reports`, `chat_messages` tables with defined schemas.  
- **API:**  
  - REST Endpoints: CRUD for reports, users, messages.  
  - Realtime Subscriptions: Chat updates, status changes.  
  - Swagger UI at `/api/v1/docs`.

## 12. Testing & QA Strategy
- **Unit Tests:** ≥ 80% code coverage for Dart logic.  
- **Integration Tests:** Critical flows: reporting, chat, notifications.  
- **E2E Tests:** Flutter Driver tests for main user journeys.  
- **Performance Tests:** Load time under network throttling; memory profiling.

## 13. Analytics & Reporting
- **Metrics Captured:** Report submissions, assignment times, chat usage, error rates.  
- **Dashboards:** Firebase Analytics & custom Supabase reports.  
- **Alerts:** Threshold-based alerts for errors, slow response times.

## 14. Compliance & Legal
- **Data Privacy:** GDPR & local regulations compliance; user consent for location.  
- **Terms & Conditions:** Accessible within app; version control.  
- **Data Retention:** Chat history & reports stored indefinitely, with archive policy review every 12 months.

## 15. Maintenance & Support
- **Support Channels:** In-app feedback form; email support.  
- **SLA:** 24-hour response time for critical issues.  
- **Versioning:** Semantic versioning (MAJOR.MINOR.PATCH).  
- **Documentation:** Developer docs (Swagger), user guide.

## 16. Future Enhancements
- Priority tagging (urgent, normal) by reporter.  
- Technician performance ratings by reporter.  
- Multi-admin support per institution.  
- Localization for additional languages.

## 17. Roadmap & Release Plan
| Milestone          | Target Date  | Deliverables                               |
|--------------------|--------------|--------------------------------------------|
| M1: Setup & Auth   | 2025-06-01   | Project init, auth integration, UI skeleton |
| M2: Reporting Flow | 2025-06-30   | CRUD reporting, GPS, photo upload           |
| M3: Real-Time      | 2025-07-15   | Chat, notifications, dashboard prototype    |
| M4: Admin Module   | 2025-08-15   | Charting, assignment workflow               |
| M5: QA & UAT       | 2025-09-01   | Testing suite, bugfixes                    |
| Beta Release       | 2025-09-15   | TestFlight & Play Store Beta                |
| Public Release     | 2025-10-01   | v1.0 live on App Stores                     |

## 18. Success Metrics
- **Issue-to-Assignment Time:** < 2 hours (avg).  
- **DAU/MAU Retention:** ≥ 40%.  
- **NPS:** ≥ 75.  
- **Error Rate:** < 1% in production.
