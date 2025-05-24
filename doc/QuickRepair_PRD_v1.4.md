# Product Requirement Document (PRD)
**Application:** QuickRepair  
**Date:** 2025-05-15 
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
  - Three user roles: Reporter, Technician, and Admin.
  - Automatic status update for reports not assigned within 24 hours.
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
### 5.1 Step-by-Step Report Creation
- **User Story:** Reporter creates a report through a guided 3-step process (Photo, Description, Location).  
- **Detail:** Integrated camera/gallery API; auto-fill GPS coordinates; location validation.
- **Acceptance:** Photo compressed ≤ 1 MB; GPS accuracy within 10 m; 3-step workflow completion.

### 5.2 Real-Time Chat & History
- **User Story:** Reporter ↔ Technician exchange messages within each report.  
- **Detail:** Supabase Realtime for bi-directional chat; reporter can edit/delete own messages.  
- **Acceptance:** Message sync latency < 1 s; persistence of history with timestamps.

### 5.3 Status Tracking & Notifications
- **User Story:** Reporter receives updates for any status change.  
- **Detail:** Status stages: New, Assigned, In Progress, Completed, Cancelled.  
- **Acceptance:** Automatic assignment after 24 hours; UI indication of status changes.

### 5.4 Profile Management
- **User Story:** Users can view and edit their profile information.  
- **Detail:** Update name, phone number, and avatar; role-based permissions.  
- **Acceptance:** Profile updates persist across sessions; avatar image optimization.

### 5.5 Onboarding Flow
- **User Story:** New user guided through introductory screens.  
- **Detail:** Illustrations + concise copy for core features.  
- **Acceptance:** Swipe navigation; skip option; shown only once per user.

## 6. Functional Requirements
| ID      | Requirement                                                              | Priority |
|---------|---------------------------------------------------------------------------|----------|
| FR-01   | Authentication & Authorization via Supabase (email)                      | High     |
| FR-02   | Photo capture/upload with preview and compression                         | High     |
| FR-03   | Automatic GPS location capture & display                                  | High     |
| FR-04   | Create, Read, Update (status), Delete reports                             | High     |
| FR-05   | Real-time chat & message management                                       | Medium   |
| FR-06   | Status change notifications                                               | High     |
| FR-07   | Public reports viewing                                                    | Medium   |
| FR-08   | Technician assignment & reassignment                                      | High     |
| FR-09   | User profile management                                                   | Medium   |
| FR-10   | Dark & Light mode support                                                 | Medium   |
| FR-11   | Onboarding screens                                                        | Medium   |
| FR-12   | English language support                                                  | High     |
| FR-13   | Error & Empty states handling                                             | Medium   |

## 7. Non-Functional Requirements
- **Performance:** ≤ 2 s screen load on 4G; image optimization for quick loading.  
- **Security:** HTTPS, Supabase row-level security, encrypted at-rest storage.  
- **Scalability:** Support 10k reports/month; horizontal scaling ready.  
- **Reliability:** 99.5% uptime; automated health checks.  
- **Accessibility:** Support for screen readers; adequate contrast ratios.
- **Maintainability:** Modular codebase, structured project organization, standard naming conventions.

## 8. Design Guidelines
- **Color Palette:** Primary Orange (#FF9800) & Accent Blue (#2196F3).  
- **Iconography:** Lucide Icons and Material Icons.  
- **Typography:** System fonts with consistent sizing.  
- **Spacing & Layout:** Consistent padding and margin patterns.  
- **Navigation Patterns:** Bottom navigation and stepper workflows.  
- **Responsiveness:** Adapt layouts for various screen sizes; support both portrait and landscape.  
- **Animations:** Subtle animations using Flutter Animate for transitions and feedback.

## 9. UI/UX & Additional Flows
- **Scope:** Mobile application frontend implementation; the centralized admin portal will be implemented in a subsequent phase.  
- **Language:** English for all UI text and notifications.  
- **Theme Support:** Default Light mode; optional Dark mode with theme provider.  
- **Error States:** Custom UI for offline, permission denial, upload failures.  
- **Empty States:** Appropriate messaging for no reports or data scenarios.

## 10. Technology Stack & Architecture
- **Front-end:** Flutter (Dart), Provider for state management.  
- **Back-end:** Supabase (PostgreSQL, Realtime, Auth, Storage).  
- **Location:** Geolocator & Geocoding packages.  
- **Image Handling:** Image Picker & Cached Network Image.  
- **UI Components:** Flutter Animate, Lottie animations, Lucide Icons.
- **Persistence:** Shared Preferences for local storage.

## 11. Data Model
- **User Model:**
  - id, email, fullName, phoneNumber, avatarUrl, role, createdAt, lastSignIn
  - Roles: Reporter, Technician, Admin

- **Report Model:**  
  - id, userId, technicianId, title, description, photoUrl, latitude, longitude, location, status, createdAt, assignedAt, completedAt, reporterId, reporterName
  - Status values: New, Assigned, In Progress, Completed, Cancelled

- **Message Model:**
  - id, reportId, userId, content, createdAt, updatedAt, deletedAt

- **Report Activity Model:**
  - id, reportId, userId, activityType, previousValue, newValue, createdAt

## 12. Testing & QA Strategy
- **Unit Tests:** Core business logic and utility functions.  
- **Widget Tests:** Testing UI components in isolation.  
- **Integration Tests:** End-to-end testing of critical user flows.  
- **Manual Testing:** Regular user testing sessions for feedback.

## 13. Analytics & Reporting
- **Metrics Captured:** Report submissions, resolution times, user engagement patterns.  
- **Dashboards:** Statistics on report status distribution and completion rates.  
- **Activity Tracking:** Comprehensive activity logging for reports.

## 14. Compliance & Legal
- **Data Privacy:** Location permission requests with clear purpose explanation.  
- **Terms & Conditions:** Accessible within app settings.  
- **Data Retention:** Report data retained with activity history.

## 15. Maintenance & Support
- **Versioning:** Semantic versioning (MAJOR.MINOR.PATCH).  
- **Documentation:** Code documentation with structured commenting.  
- **Error Handling:** Comprehensive error handling with user-friendly messages.

## 16. Future Enhancements
- Web-based admin dashboard implementation.
- Priority tagging (urgent, normal) by reporter.
- Technician performance ratings.
- Multi-language support.
- Offline mode with synchronization.

## 17. Release Plan
| Milestone          | Deliverables                                             |
|--------------------|----------------------------------------------------------|
| M1: Setup & Auth   | Project structure, authentication, user profiles         |
| M2: Reporting      | Report creation workflow, photo upload, location services |
| M3: Real-Time      | Chat implementation, status updates, notifications       |
| M4: UI Polish      | Theme support, animations, accessibility improvements    |
| M5: Testing        | Comprehensive testing and bug fixes                      |
| Public Release     | v1.0 on App Stores                                       |

## 18. Success Metrics
- **Issue-to-Assignment Time:** < 2 hours (avg).  
- **DAU/MAU Retention:** ≥ 40%.  
- **NPS:** ≥ 75.  
- **Error Rate:** < 1% in production.
