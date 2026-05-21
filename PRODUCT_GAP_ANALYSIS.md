# Product Gap Analysis — Neighborly Fleet Management
**Perspective:** Product Owner
**Date:** 2026-05-20
**Product Vision:** A white-label, AI-powered fleet management application enabling fleet operators to deliver a modern, intelligent ride experience to their riders.

---

## Executive Summary

The application has a well-structured technical foundation — the backend API is nearly complete and the data layer is solid. However, viewed against the white-label, AI-powered product vision, there are **significant gaps** across four dimensions:

1. **There is no AI** — the product's core differentiator does not exist yet
2. **It is not white-label ready** — there is no branding, configuration, or multi-tenant layer
3. **Several user journeys are broken or missing** — riders and drivers hit dead ends
4. **Operational tooling for fleet operators is thin** — they cannot run a real business from this app alone

The product is approximately **40% complete** against its stated vision.

---

## 1. The AI Gap — Highest Priority

The product is positioned as an "AI-based ride experience." Nothing AI exists in the current build. What exists is rules-based logic that is commonly available in any dispatch system.

| What's Built | What Was Promised |
|---|---|
| Haversine distance sort to pick nearest driver | AI-powered dispatch (demand prediction, multi-variable optimization) |
| Fixed 3-attempt reassignment with no learning | Adaptive reassignment that learns from driver behavior |
| Static platform fee set by admin | Dynamic, AI-driven pricing based on demand, time, route |
| No ETA confidence | Predictive ETA with ML-based traffic awareness |
| No personalization | Personalized rider experience (preferred driver, saved routes, preferences) |

### Specific AI features to define and build

**Dispatch Intelligence**
- Demand forecasting: predict ride volume by time, location, fleet to pre-position drivers
- Multi-factor driver scoring: combine proximity + historical acceptance rate + driver rating + current shift hours to select the best driver, not just the nearest one
- Reassignment learning: track why a driver declined (busy, off-route) and use that to skip them sooner next time

**Pricing Intelligence**
- Dynamic surge pricing based on real-time demand vs. driver supply within a fleet's service area
- Route-based fare estimation before booking (currently fare is set to 0 at booking and calculated later — rider has no price visibility before confirming)

**Rider Experience**
- Predictive ETA: show confidence intervals, not just a single duration string from Google Places
- Smart scheduling: suggest optimal pickup times based on historical patterns
- Saved places and frequent routes

**Operations Intelligence (for fleet managers)**
- Driver utilization scores and shift optimization suggestions
- Underperforming driver alerts
- Revenue anomaly detection ("your earnings dropped 30% this week vs. last")

---

## 2. White-Label Readiness Gaps

A white-label product means any fleet company can deploy it under their own brand. The current build has no white-label layer whatsoever.

### 2.1 Branding & Theming

**Missing entirely:**
- No theme configuration system — colors, fonts, logo are hardcoded (Neighborly blue)
- No per-fleet app name, splash screen, or icon configuration
- No way for a fleet operator to upload and apply their brand identity from a dashboard
- Email templates are inline strings — no branded email design, no per-fleet sender name

**Required:**
- A `BrandConfig` entity/service that stores per-fleet primary color, logo URL, app name, support contact
- Flutter theming driven by remote config (fetch brand config at startup, apply `ThemeData` dynamically)
- Branded transactional email templates (invite, BGC result, receipt, approval)

### 2.2 Multi-Tenant Architecture

**Current state:** The system assumes one Neighborly platform. Fleet managers are users within that platform. There is no concept of an isolated tenant.

**Gaps:**
- A fleet company deploying this as their own product cannot have isolated data — all fleets share the same database with no tenant boundary
- No per-tenant subdomain or API namespace
- No tenant-level admin (fleet company's own superadmin vs. Neighborly platform admin)
- No tenant onboarding flow (a new fleet company signing up for the white-label product)

### 2.3 Configuration & Self-Service

**Missing:**
- Fleet operators cannot configure their own service area (geographic boundaries)
- Fleet operators cannot set their own working hours / operational hours
- Fleet operators cannot define their own vehicle types or categories
- Fleet operators cannot configure pricing rules (base fare, per-km rate) — only the platform fee % is configurable
- No Terms of Service or Privacy Policy per fleet company (legal gap for white-label)

---

## 3. Broken & Missing User Journeys

### 3.1 Rider Journey — Critical Gaps

| Step | Status | Gap |
|---|---|---|
| Discover fleet tribes | Built | Search bar renders but does not filter results |
| Join tribe | Built | Returns `{ status: 'pending' }` when `auto_approve_riders = false` — rider has no way to track this pending state or get notified when approved |
| Book a ride | Partial | Pickup/dropoff fields exist but use **hardcoded coordinates** — no map picker or address autocomplete. Rider cannot actually specify a location |
| See fare before booking | Missing | Fare is 0 at booking time. Rider books blind with no price estimate |
| Wait for driver assignment | Missing | No waiting screen exists. After booking, rider has no feedback that anything is happening |
| Track driver in real-time | Missing | No live map or driver location during ride. This is a table-stakes feature for any ride product |
| Receive receipt | Partial | Backend sends email receipt. No in-app receipt screen exists |
| Rate the ride | Missing entirely | No rating or review flow for riders after a fleet ride |

### 3.2 Driver Journey — Critical Gaps

| Step | Status | Gap |
|---|---|---|
| Accept fleet invite via email link | Built | Works |
| Background check document submission | Missing | `background_check_screen.dart` referenced in Plan but does not exist. Driver has no UI to submit BGC documents |
| Know their BGC status | Missing | No status tracking screen. Driver accepts invite and then has no visibility into what happens next |
| See active ride on a map | Missing | No active ride screen. Driver accepts assignment and has no in-app navigation |
| Mark ride as in-progress | Missing | Status goes from ACCEPTED → COMPLETED. There is no STARTED/IN_PROGRESS transition — driver cannot signal they have picked up the rider |
| Earnings summary | Missing | Driver has no screen to view their own earnings history |
| Rate the rider | Missing | No rider rating flow for drivers |

### 3.3 Fleet Manager Journey — Gaps

| Step | Status | Gap |
|---|---|---|
| Register fleet | Built | Works |
| Upload company logo | Missing | `logo_url` field exists in the model but there is no file upload UI. Registration form has no logo picker |
| Set up Stripe payments | Partial | Flow exists but depends on parent app's `features/auth/stripe_onboarding_screen.dart`. Return-from-Stripe lifecycle handling is incomplete |
| View pending rider join requests | Missing | When `auto_approve_riders = false`, manager is notified via push but has no screen to see and act on the list of pending applicants |
| View ride history | Missing | `GET /fleet/:fleetId/rides` endpoint exists but there is no rides list screen in the app |
| Manage service area | Missing | No geographic zone definition — fleet can receive bookings from anywhere |
| Communicate with drivers | Missing | No in-app messaging or broadcast notification to driver pool |
| Export reports | Missing | No CSV/PDF export for payouts or ride history (common requirement for finance teams) |

---

## 4. Real-Time Features — Entirely Absent

For a ride product, real-time is not optional. Everything below is missing:

- **Live driver location on rider's map** — rider cannot see where their driver is
- **Live ETA updates** — ETA is calculated once at booking; never updated as the ride progresses
- **Real-time ride status push** — driver accepts → rider's screen should update automatically, not require a manual refresh
- **Driver availability indicator** — fleet manager has no visibility into which drivers are currently online and available
- **WebSocket or SSE connection** — no real-time transport layer defined (backend uses REST only)

---

## 5. Payments & Financial Gaps

| Gap | Detail |
|---|---|
| No fare calculation engine | Fare is set to `0` at ride creation. No pricing engine connected to fleet rides. Rider has no pre-booking price estimate |
| Stripe webhook not handling account ID persistence | When a fleet manager completes Stripe Connect onboarding, the `stripe_account_id` is not persisted. The webhook handler is missing. Fleet payouts will silently fail |
| No refund flow | No mechanism to issue a refund if a ride is cancelled after payment capture |
| No payout schedule configuration | Plan.md lists `STRIPE_PAYOUT_SCHEDULE=manual` — fleet managers cannot choose their own payout frequency |
| No invoice generation | Fleet companies typically need invoices, not just ride receipts |
| Driver earnings not paid by platform | Per non-goals, drivers are paid off-platform. But the app gives drivers no visibility into what they earned per ride, making this a trust problem |

---

## 6. Notifications — Incomplete

The notification architecture exists but is half-built.

| Notification | Backend | Frontend Handler |
|---|---|---|
| Admin: new fleet application | Sent | Missing — admin has no fleet management UI |
| Manager: fleet approved | Sent | Missing — app doesn't route to dashboard on launch for approved managers |
| Manager: fleet rejected | Email only | Missing in-app |
| Manager: driver accepted invite | Sent | No dedicated screen |
| Manager: BGC result | Sent | No dedicated screen |
| Manager: rider join request | Sent | No pending requests screen |
| Driver: ride assigned (60s window) | Sent | Assignment screen exists but no push listener to trigger it automatically |
| Rider: driver accepted | Sent | No ride tracking screen to update |
| Rider: ride cancelled (no drivers) | Missing | Backend cancels the ride but does not notify the rider |
| Manager: payout processed | Sent | Dashboard shows payouts but no push |

**Core problem:** Push notifications are sent from the backend, but the Flutter app has no push notification listener / handler configured in the fleet module. Notifications arrive on the device but nothing happens in the app.

---

## 7. Admin Portal — Not Built

The backend has a complete admin API (approve/reject fleets, set fees, view platform analytics). There is no admin UI.

Platform admins must currently use raw API calls (e.g., Postman) to:
- Review and approve fleet applications
- Set per-fleet platform fees
- Suspend fleets
- View platform-wide revenue

This is not viable for a real product. A web-based admin panel is needed.

---

## 8. Non-Functional & Operational Gaps

| Area | Gap |
|---|---|
| **Search & Discoverability** | Fleet tribe search bar renders but does not work. No pagination loading indicator |
| **Offline handling** | No offline state management. App crashes silently if network is unavailable mid-booking |
| **Input validation** | Phone number and address fields have no format validation on the frontend |
| **Security** | BGC webhook uses a shared secret but the secret is not yet defined in the env. If not set, the check short-circuits and any caller can mark BGC as passed |
| **Rate limiting** | No rate limiting on invite endpoints — a manager could flood a driver's inbox |
| **Accessibility** | No semantic labels, no screen reader support tested |
| **Internationalisation** | All strings are hardcoded in English. No i18n framework |
| **Analytics / Telemetry** | No product analytics (Mixpanel, Amplitude) to understand user behavior |
| **Error logging** | No error tracking service (Sentry, Datadog) configured |
| **App Store readiness** | App has no onboarding screens, no terms acceptance, no privacy policy flow — would be rejected by both App Store and Play Store |

---

## 9. Gap Severity Matrix

| Gap | User Impact | Effort | Priority |
|---|---|---|---|
| No AI dispatch/pricing | Undermines product positioning | High | P0 — Define AI strategy first |
| No fare shown before booking | Rider cannot make informed decision | Medium | P0 |
| No map/location picker | Rider literally cannot book a ride | Medium | P0 |
| Stripe webhook missing | Payouts will fail silently | Low | P0 |
| No ride waiting / active screens | Rider and driver both stranded after booking | Medium | P0 |
| No push notification listener | All backend notifications are invisible | Low | P0 |
| No BGC document upload screen | Driver onboarding is broken | Low | P1 |
| No pending join requests screen | Manager cannot manage tribe access | Low | P1 |
| No ride history screen | Manager cannot review operations | Low | P1 |
| No admin web portal | Platform cannot be operated | High | P1 |
| No real-time location | No trust in driver ETA | High | P1 |
| No white-label theming | Cannot sell to other fleet companies | Medium | P1 |
| No fare engine | Rides have $0 fare | Medium | P1 |
| No rating/review flow | No quality signal for fleet operators | Low | P2 |
| No rider notification when cancelled | Rider is left waiting with no feedback | Low | P2 |
| No driver earnings screen | Driver has no visibility into pay | Low | P2 |
| No report export | Finance teams cannot use the product | Low | P2 |
| Search not functional | Minor UX gap | Low | P2 |
| No i18n | Limits international white-label market | Medium | P3 |
| No accessibility | Compliance and inclusion gap | Medium | P3 |

---

## 10. Recommended Next Steps

### Immediate (before any more feature work)
1. **Define the AI strategy** — What does "AI-based ride experience" mean specifically? Which AI features are in scope for v1? Without this decision, the core product promise cannot be scoped or built.
2. **Fix the booking flow** — A ride cannot be booked without a location picker. This is the single most critical functional gap.
3. **Fix Stripe webhook** — Payouts are broken. Revenue cannot flow until this is resolved.

### Short-term (v1 MVP)
4. Build ride waiting, active ride, and receipt screens
5. Add push notification listener to the Flutter app
6. Build BGC document upload screen
7. Build pending tribe join requests screen for fleet managers
8. Build rides list / history screen
9. Add fare estimation before booking

### Medium-term (v1.5 — white-label readiness)
10. Build per-fleet branding/theming system
11. Build admin web portal
12. Implement real-time driver location (WebSocket or polling)
13. Integrate a fare calculation engine

### Longer-term (v2 — AI)
14. Design and instrument data collection for ML training
15. Build demand forecasting model
16. Build multi-factor driver scoring model
17. Implement dynamic pricing
