# Product Requirements Document

> Veritas Prototype 0.1 · Centralized Multi-Branch Clinic Administration System
> Baseline: 16 October 2026 · Status: interactive owner-dashboard prototype

Defines the problem, intended users, current product behavior, and requirements for future clinic operations.

Related documents: [Architecture](ARCHITECTURE.md) · [Design system](DESIGNSYSTEM.md) · [Workflows](WORKFLOW.md)

## 01 · Product overview

| Field | Definition |
|---|---|
| Project | Veritas Prototype 0.1 |
| Current UI brand | Vista Care |
| Purpose | Help authorized clinic management understand branch performance and operational needs |
| Current users | A simulated clinic owner; no authenticated user accounts |
| Intended reach | Six branches with Pasig as the proposed central administration hub |
| Branches | Laguna, Pasig, Caloocan, Parañaque, Quezon City, Valenzuela |
| Current platform | Flutter application with Android and Chrome development usage |
| Current storage | Laravel REST API with persistent local SQLite; explicit demo mode remains in-memory |

The product should give management one place to compare visits, collections, expenses, reports, and medicine inventory. The broader vision includes controlled patient records, billing, doctor attendance, scheduling, and auditability.

## 02 · Problem and goals

Information spread across branches makes it difficult to know which reports are complete, where supplies need attention, and how performance compares. The original workflow also identifies the need to protect clinical information and coordinate doctors across locations.

### Prototype goals

1. Demonstrate an understandable overview of six branches.
2. Let reviewers filter by branch and compare daily, seven-day, and thirty-day information.
3. Demonstrate report entry/editing and inventory updates with immediate UI feedback.
4. Show useful stock and expiry alerts.
5. Provide responsive layouts and an iPhone screen preview for design review.

### Production goals

Create durable, shared operations with server-enforced permissions, traceable changes, and reliable cross-branch coordination. Production goals are requirements for future work; they are not features delivered by this prototype.

### Out of scope

A patient-facing portal, online patient self-service, payment-gateway integration, automated clinical decisions, and automated fraud accusations are outside the current scope. Individual medical records and actual payments must not be inferred from aggregate report screens.

## 03 · Users and permissions

The following roles come from the intended clinic workflow. **None of these permissions is currently enforced by the application.**

| Role | Intended responsibility |
|---|---|
| Owner / CEO / main administrator | Authorized oversight across all six branches; users, roles, reports, alerts, audit review |
| Pasig branch manager | Pasig operations; central access only if separately authorized |
| Other branch manager | Operations and reports for the assigned branch |
| Reception | Basic registration, patient identity search, appointment creation |
| Billing staff | Services, payments, refunds, sales reporting; no medical notes |
| Inventory staff | Stock movements, requests, expiry and adjustments; no clinical records |
| Nurse / authorized staff | Minimum information required for assigned clinic service |
| Doctor | Authorized clinical history and clinical notes; billing only with separate permission |

Owner visibility of operational data does not automatically grant unrestricted access to clinical notes. Production policies must define sensitive-data access by purpose, role, resource, and branch.

## 04 · Current functional requirements

“Implemented” below means present in the inspected source, not deployed as a production service.

| ID | Feature | Current behavior / acceptance criterion |
|---|---|---|
| C01 | Owner navigation | Five sections are reachable on mobile and desktop; inventory is reachable from relevant shortcuts |
| C02 | Branch scope | Selecting a branch limits dashboard views and related totals; “All branches” restores combined scope |
| C03 | Overview | Show daily visits, collections, branch summaries, and inventory attention items from sample data |
| C04 | Daily reports | Select today or a past date within the picker range; view and create/edit branch reports |
| C05 | Report validation | Patients are nonnegative integers; revenue/expenses are finite nonnegative numbers; notes are optional |
| C06 | Report replacement | Saving the same branch/date replaces its report rather than double counting it |
| C07 | Statistics | Switch between seven and thirty days; show visit totals, averages, comparisons, and sample staff ratings |
| C08 | Revenue | Switch today/seven/thirty days; show gross, expenses, net, and guarded net-margin calculation |
| C09 | Branch details | Show address, daily target, visits, inventory overview, trend, and sample staff information |
| C10 | Inventory search | Search medicine or branch text; switch all batches / needs attention |
| C11 | Batch creation | Require a medicine name, nonnegative integer quantity and threshold, unit, branch, and expiry |
| C12 | Stock changes | Add a positive whole-number restock or set a nonnegative corrected on-hand quantity |
| C13 | Alerts | Flag quantity at/below threshold, expired dates, and expiry within 60 days |
| C14 | Responsive motion | Use responsive navigation and animated tab/card/chart transitions with reduced-motion handling |
| C15 | Device preview | Debug starts with an iPhone 16 simulation; an opt-out flag restores host dimensions |

Batch units are vials, tablets, capsules, bottles, or boxes. The batch date picker accepts today through approximately ten years ahead. Different expiry deliveries should use separate batches.

Daily reports currently contain patient count, gross revenue, operating expenses, and notes. The “Submitted” label is a stored report display state; it is not evidence of manager approval or a formal submission workflow. API saves now wait for server confirmation.

## 05 · Planned functional requirements

These preserve the original workflow's intended scope. P03 is partially implemented locally; production identity, policies, conflict handling, and deployment remain open.

| ID | Priority | Requirement and acceptance condition |
|---|---|---|
| P01 | Foundation | Authenticate users; deny invalid access and record the outcome |
| P02 | Foundation | Enforce role, branch, module, and action checks on every server request, including direct resource access |
| P03 | Foundation | Persist shared data across restarts and clients; expose failed/conflicting writes clearly |
| P04 | Foundation | Record logins, access requests, edits, refunds, stock adjustments/transfers, and report submissions in a restricted audit trail |
| P05 | Operations | Search/create centralized patient identities; reception sees basic registration only |
| P06 | Operations | Limit clinical records by permission; only authorized doctors edit clinical notes with history |
| P07 | Operations | Support cross-branch information requests, authorized review, minimal release, denial reasons, and audit records |
| P08 | Operations | Record QR time-in/time-out, assigned/actual branch, schedule, and attendance status |
| P09 | Operations | Detect doctor/appointment branch or time conflicts; notify branch and Pasig administrators and record human resolution |
| P10 | Operations | Record services, payments, and manager-reviewed refunds with reasons; keep billing separate from clinical notes |
| P11 | Operations | Track stock-in/out, usage, adjustments, movement history, and inventory discrepancies |
| P12 | Operations | Approve stock transfers and update both branch inventories atomically; route unavailable stock to replenishment requests |
| P13 | Operations | Review and submit daily operational reports after closing, preferably after 5 PM clinic time |
| P14 | Management | Consolidate reports and alerts for authorized Pasig/owner users, including attendance and scheduling conflicts |
| P15 | Management | Deliver notifications through selected channels with traceable outcomes; alerts require human review |
| P16 | Management | Add returning-patient/follow-up and fast-moving-supply views once underlying events exist |

P13 expands the report to include services, refunds, inventory movements, low-stock items, attendance, doctor schedule status, and appointment conflicts. A “preferably after 5 PM” process guideline is not currently a hard application cutoff.

## 06 · Nonfunctional requirements

| Area | Requirement / current limitation |
|---|---|
| Access control | Must be enforced by the server; current branch selectors are display filters |
| Durability | Local API saves survive restart and can be refreshed by clients of the same server; production authorization/deployment remain planned |
| Correctness | Avoid duplicate branch/date reports; define precision, conflict, and correction rules |
| Privacy | Minimize exposed fields and segregate clinical and billing access |
| Auditability | Record actor, action, scope, time, result, and meaningful change context |
| Accessibility | Verify contrast, keyboard operation, large text, chart alternatives, and reduced motion |
| Performance | Avoid blocking interactions and unnecessary rebuilds; establish a device-based performance baseline |
| Reliability | Define retries, error states, backups, restore procedures, and service monitoring |
| Time | Use a consistent Philippine clinic-day policy; production timestamps need an authoritative source |

No uptime, response-time, legal-compliance, or accessibility-certification claims are established by this prototype.

## 07 · Key journeys

| Journey | Expected outcome |
|---|---|
| Owner opens dashboard → selects Pasig | Only Pasig-scoped overview data is displayed |
| Owner edits today's branch report | Dashboard totals reflect the replacement without adding a second report |
| Reviewer opens stock alerts → restocks low batch | Low-stock condition clears when quantity exceeds threshold; expiry attention can remain |
| Reviewer adds a different-expiry delivery | A new batch appears without changing the old batch's expiry |
| Reviewer changes tabs | Directional motion completes and controls remain usable |
| Future branch employee requests another branch's records | Server evaluates policy and approval; no unrestricted direct access |

Detailed steps and exceptions are in [WORKFLOW.md](WORKFLOW.md).

## 08 · Success measures and acceptance

The prototype has no analytics pipeline or measured adoption baseline. Do not treat proposed measures as achieved results.

| Measure | Acceptance / evaluation method |
|---|---|
| Navigation completeness | Every primary section and inventory route is reachable |
| Calculation consistency | Filtered totals agree with underlying reports and report replacement does not double count |
| Stock behavior | Restock/correction updates quantities and all relevant attention predicates |
| Layout quality | Existing widget scenarios at 320 and 1440 px pass; review iPhone layout manually |
| Task usability | Observe reviewers completing filter, report, and inventory tasks without assistance; record issues |
| Future permission coverage | Every role/branch allow/deny scenario has server/integration tests before pilot |
| Future durability | Restart and multi-client tests confirm committed data persists |
| Future audit completeness | Every defined auditable operation produces a reviewable record |

Numerical task-time and satisfaction targets should be agreed after initial user testing. The reference PRD image's generic user-growth targets do not apply to this internal clinic prototype.

## 09 · Delivery stages

1. **Prototype baseline — present:** owner views, sample data, report/inventory forms, responsive UI, motion, Device Preview.
2. **Production foundation — planned:** identity, permissions, backend, persistence, audit, errors and conflict handling.
3. **Branch operations — planned:** patient information, billing, attendance, appointment coordination, stock movements and approvals.
4. **Central monitoring — planned:** complete daily reporting, notifications, returning patients/follow-ups, supply movement analysis.

No delivery dates or backend vendors have been committed.

## 10 · Risks, assumptions, and open decisions

- Confirm whether the public name should remain Vista Care or change to Veritas.
- Validate the six branch names and Pasig's central-administration responsibilities.
- Confirm who may approve cross-branch access, transfers, refunds, and report corrections.
- Select hosting, identity, storage, and notification providers before production implementation.
- Define report finalization, late changes, money precision, retention, and offline behavior.
- Validate that sample staff ratings, addresses, growth figures, and medicine quantities are replaced or clearly labeled in every demonstration.
- Require human review of discrepancies and conflicts; do not infer misconduct from an alert.

Existing automated coverage is in [store tests](frontend/test/clinic_store_test.dart) and [widget tests](frontend/test/widget_test.dart). Scope changes must update the architecture, workflow, and design documents alongside this PRD.


## REST integration update - 18 October 2026

Flutter now uses Laravel REST requests by default. Branches, daily reports, and medicine batches are stored in SQLite. Confirmed saves persist; errors preserve forms; refresh reloads server state. Explicit USE_DEMO_DATA=true builds remain in-memory, including GitHub Pages. Production login, permissions, audit history, approvals, and hosted API deployment remain planned.
