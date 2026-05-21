# Neighborly Fleet Management — Implementation Plan

## Overview

This document describes the implementation plan for the Neighborly Fleet Management feature, based on analysis of the BRD and the existing mobile application codebases.

**Existing Stack:**
- **Backend**: NestJS (TypeScript) + TypeORM + PostgreSQL + Redis + Stripe Connect + Firebase Notifications + AWS SES
- **Frontend**: Flutter (Dart) + BLoC + get_it/injectable + Hive + Provider

---

## Folder Structure

```
neighborly-fleet-management/
├── Plan.md                          ← This file
├── backend/                         ← NestJS fleet module (extends neighborly_backend)
│   └── src/
│       └── fleet/
│           ├── fleet.module.ts
│           ├── fleet.controller.ts
│           ├── fleet.service.ts
│           ├── entities/
│           │   ├── fleet.entity.ts
│           │   ├── fleet-driver.entity.ts
│           │   └── fleet-invite.entity.ts
│           ├── dto/
│           │   ├── create-fleet.dto.ts
│           │   ├── update-fleet.dto.ts
│           │   ├── invite-driver.dto.ts
│           │   ├── respond-invite.dto.ts
│           │   └── fleet-query.dto.ts
│           ├── controllers/
│           │   ├── fleet-admin.controller.ts
│           │   ├── fleet-driver.controller.ts
│           │   └── fleet-ride.controller.ts
│           ├── services/
│           │   ├── fleet-registration.service.ts
│           │   ├── fleet-driver.service.ts
│           │   ├── fleet-ride.service.ts
│           │   ├── fleet-payout.service.ts
│           │   └── fleet-analytics.service.ts
│           └── migrations/
│               ├── CreateFleetTable.ts
│               ├── CreateFleetDriverTable.ts
│               ├── AddFleetTribeType.ts
│               └── AddFleetIdToRides.ts
└── frontend/                        ← Flutter fleet modules (extends neighborly_app)
    └── lib/
        └── fleet/
            ├── domain/
            │   ├── fleet_manager/
            │   │   ├── fleet_manager_repository.dart
            │   │   └── models/
            │   │       ├── fleet.dart
            │   │       ├── fleet_driver.dart
            │   │       └── fleet_analytics.dart
            │   └── fleet_ride/
            │       ├── fleet_ride_repository.dart
            │       └── models/
            │           └── fleet_ride.dart
            ├── infrastructure/
            │   ├── fleet_manager/
            │   │   └── i_fleet_manager_repository.dart
            │   └── fleet_ride/
            │       └── i_fleet_ride_repository.dart
            └── presentation/
                ├── fleet_manager/
                │   ├── registration/
                │   │   ├── fleet_registration_screen.dart
                │   │   ├── stripe_onboarding_screen.dart
                │   │   └── fleet_pending_approval_screen.dart
                │   ├── dashboard/
                │   │   ├── fleet_dashboard_screen.dart
                │   │   ├── fleet_earnings_widget.dart
                │   │   └── fleet_stats_widget.dart
                │   └── drivers/
                │       ├── fleet_driver_roster_screen.dart
                │       ├── invite_driver_screen.dart
                │       └── driver_detail_screen.dart
                ├── fleet_driver/
                │   ├── onboarding/
                │   │   ├── fleet_invite_accept_screen.dart
                │   │   └── background_check_screen.dart
                │   └── rides/
                │       └── fleet_ride_assignment_screen.dart
                └── rider/
                    ├── fleet_tribe_discovery_screen.dart
                    ├── fleet_tribe_detail_screen.dart
                    └── fleet_ride_booking_screen.dart
```

---

## Data Model Changes

### New Entities (Backend)

#### 1. `Fleet` entity
```
fleet_id          uuid (PK)
company_name      varchar(200)
company_email     varchar(255) unique
company_phone     varchar(20)
company_address   text
logo_url          varchar(500)
status            enum: PENDING_APPROVAL | APPROVED | REJECTED | SUSPENDED
stripe_account_id varchar(255)          ← links to existing StripeConnectAccount
platform_fee_pct  decimal(5,2)          ← set by Neighborly Admin (default 10%)
manager_user_id   uuid → FK users.id
tribe_id          uuid → FK communities.community_id (auto-created on approval)
created_at        timestamp
updated_at        timestamp
```

#### 2. `FleetDriver` join table
```
id                uuid (PK)
fleet_id          uuid → FK fleets.fleet_id
driver_user_id    uuid → FK users.id
status            enum: INVITED | BGC_PENDING | ACTIVE | INACTIVE | REJECTED
invite_token      varchar(255) unique    ← used for email invite link
invite_expires_at timestamp
bgc_request_id    varchar(255)          ← background check vendor ref
activated_at      timestamp
created_at        timestamp
updated_at        timestamp
```

#### 3. `FleetInvite` (audit log)
```
id                uuid (PK)
fleet_id          uuid → FK
invited_email     varchar(255)
invite_token      varchar(255)
sent_at           timestamp
accepted_at       timestamp (nullable)
status            enum: PENDING | ACCEPTED | EXPIRED
```

### Existing Entity Modifications

| Entity | Change |
|---|---|
| `Community` | Add `type` enum (PERSONAL \| FLEET), `fleet_id` FK (nullable) |
| `Ride` | Add `fleet_id` FK (nullable), `assignment_attempts` int (default 0) |
| `User` | Add `fleet_manager_of` nullable FK, `fleet_member_of` nullable FK |
| `UserRole` enum | Add `FLEET_MANAGER = 'fleet_manager'` |

---

## API Endpoints

### Fleet Registration & Admin (Fleet Manager + Platform Admin)

| Method | Path | Description | Guard |
|---|---|---|---|
| POST | `/fleet/register` | Submit fleet company registration | Auth (rider/fleet_manager) |
| GET | `/fleet/:id` | Get fleet profile | Auth |
| PATCH | `/fleet/:id` | Update fleet profile | FleetManager |
| POST | `/admin/fleet/:id/approve` | Approve fleet application | Admin |
| POST | `/admin/fleet/:id/reject` | Reject fleet application | Admin |
| POST | `/admin/fleet/:id/suspend` | Suspend a fleet | Admin |
| PATCH | `/admin/fleet/:id/fee` | Set platform fee percentage | Admin |
| GET | `/admin/fleets` | List all fleets (with filters) | Admin |

### Driver Management (Fleet Manager)

| Method | Path | Description | Guard |
|---|---|---|---|
| POST | `/fleet/:id/drivers/invite` | Send invite email to driver | FleetManager |
| GET | `/fleet/:id/drivers` | List fleet drivers + status | FleetManager |
| PATCH | `/fleet/:id/drivers/:driverId/activate` | Activate a driver | FleetManager |
| PATCH | `/fleet/:id/drivers/:driverId/deactivate` | Deactivate a driver | FleetManager |
| GET | `/fleet/invite/:token` | Validate invite token (public) | Public |
| POST | `/fleet/invite/:token/accept` | Accept invite (creates/links driver) | Auth |

### Fleet Tribe & Rider

| Method | Path | Description | Guard |
|---|---|---|---|
| GET | `/fleet/tribes` | Discover public fleet tribes | Auth |
| POST | `/fleet/tribes/:tribeId/join` | Rider requests to join | Auth (rider) |
| POST | `/fleet/tribes/:tribeId/members/:userId/approve` | Approve rider | FleetManager |
| DELETE | `/fleet/tribes/:tribeId/members/:userId` | Remove rider | FleetManager |

### Fleet Ride Booking

| Method | Path | Description | Guard |
|---|---|---|---|
| POST | `/fleet/rides` | Rider books a fleet ride | Auth (rider) |
| GET | `/fleet/rides` | List fleet rides | FleetManager / Driver |
| POST | `/fleet/rides/:rideId/assign` | (internal) Assign to best driver | System |
| POST | `/fleet/rides/:rideId/accept` | Driver accepts assignment | Auth (driver) |
| POST | `/fleet/rides/:rideId/decline` | Driver declines (triggers reassign) | Auth (driver) |

### Fleet Analytics & Payouts

| Method | Path | Description | Guard |
|---|---|---|---|
| GET | `/fleet/:id/analytics` | Earnings, rides, driver stats | FleetManager |
| GET | `/fleet/:id/payouts` | Payout history | FleetManager |
| POST | `/fleet/:id/payouts/trigger` | Trigger manual payout | Admin |

---

## Business Logic

### Fleet Registration Flow
1. Fleet Manager submits registration form → `Fleet` created with status `PENDING_APPROVAL`
2. Stripe Connect onboarding link generated and presented to manager
3. Platform Admin reviews application → approves or rejects
4. On approval:
   - Fleet status → `APPROVED`
   - `Community` record auto-created with `type = FLEET`, linked to fleet
   - Manager notified via push + email

### Driver Invite & Onboarding Flow
1. Fleet Manager submits driver email → `FleetInvite` + `FleetDriver` (status: `INVITED`) created
2. Email sent via existing `EmailService` with signed invite token (JWT, 7-day expiry)
3. Driver opens invite link → validates token → accepts
4. Background check triggered → `FleetDriver.status → BGC_PENDING`
5. On BGC pass → `FleetDriver.status → ACTIVE`, driver added to Fleet Tribe community
6. On BGC fail → `FleetDriver.status → REJECTED`, manager notified

### Smart Driver Assignment (60-second window)
1. Rider books fleet ride → system queries all `ACTIVE` fleet drivers in the tribe
2. Drivers sorted by: proximity to pickup (haversine distance on `lastLocation`) → schedule availability
3. Best driver receives push notification + ride request record
4. 60-second Redis TTL key set for the assignment
5. If driver accepts within 60s → ride proceeds
6. If 60s expires or driver declines → system attempts next driver (up to 3 attempts)
7. If all fail → ride status → `UNASSIGNED`, rider notified

### Payment Flow (extends existing Stripe logic)
1. Rider payment captured on ride start (existing Stripe payment intent flow)
2. On ride completion:
   - Look up `fleet.platform_fee_pct`
   - Calculate: `platform_fee = fare × platform_fee_pct / 100`
   - `net_payout = fare - platform_fee`
   - Transfer `net_payout` to `fleet.stripe_account_id` via Stripe Transfer API
3. Payout record created, fleet dashboard updated, receipt emailed to rider

---

## Implementation Phases

### Phase 1 — Fleet Registration & Admin Approval (Weeks 1–2)

**Backend:**
- [ ] `CreateFleetTable` migration
- [ ] `Fleet` entity
- [ ] `FleetModule` scaffold
- [ ] `FleetRegistrationService`: create fleet, initiate Stripe Connect onboarding (reuse `StripeConnectService`)
- [ ] `FleetAdminController`: approve/reject/suspend, set fee
- [ ] Extend `UserRole` enum with `FLEET_MANAGER`
- [ ] Add `FleetManagerGuard`
- [ ] Admin notification on new fleet registration (reuse `NotificationService` + `EmailService`)

**Frontend:**
- [ ] Fleet Manager registration screen (company name, email, phone, address, logo upload)
- [ ] Stripe Connect web-view / redirect for onboarding
- [ ] "Pending Approval" holding screen
- [ ] Admin portal: fleet application list with approve/reject actions
- [ ] New `FleetManagerRepository` + BLoC

**Integration Points:**
- Reuse `StripeConnectService.createConnectAccount()`
- Reuse `UploadService` for company logo
- Reuse `AdminModule` for approval endpoints

---

### Phase 2 — Driver Onboarding & Fleet Tribe Creation (Weeks 3–4)

**Backend:**
- [ ] `CreateFleetDriverTable` migration + `AddFleetTribeType` migration
- [ ] `FleetDriver` + `FleetInvite` entities
- [ ] `FleetDriverService`: invite by email, validate token, accept invite
- [ ] Background check integration hook (stub with existing vendor pattern from `driver-application.service.ts`)
- [ ] Auto-create Fleet Tribe (`Community` with `type=FLEET`) on fleet approval (inside registration service)
- [ ] Driver activation → add to tribe community via existing `CommunitiesService`
- [ ] `FleetDriverController` (invite, accept, roster, activate/deactivate)

**Frontend:**
- [ ] Driver invite acceptance screen (opened from email deep link)
- [ ] Background check submission screen (document upload via existing `UploadModule`)
- [ ] Fleet Manager: driver roster screen with status badges
- [ ] Fleet Manager: invite driver modal
- [ ] Fleet Driver: onboarding status screen

**Integration Points:**
- Reuse `EmailService.sendEmail()` for invite emails
- Reuse `AppLinkUtil` for deep link handling of invite tokens
- Reuse `UploadService` / `S3` for BGC document uploads
- Reuse `CommunitiesService` to add driver to Fleet Tribe

---

### Phase 3 — Fleet Ride Booking & Payment Flow (Weeks 5–6)

**Backend:**
- [ ] `AddFleetIdToRides` migration + `AddAssignmentAttemptsToRides` migration
- [ ] `FleetRideService`: book fleet ride, smart assignment, accept/decline, reassignment
- [ ] Redis TTL logic for 60-second assignment window (extend `RideExpirationService`)
- [ ] `FleetPayoutService`: on ride completion, calculate fee split and initiate Stripe Transfer
- [ ] Rider tribe membership check before booking
- [ ] Fleet ride controller endpoints

**Frontend:**
- [ ] Rider: Fleet Tribe discovery & join request screen
- [ ] Rider: Fleet ride booking screen (time + location, no driver selection)
- [ ] Rider: waiting for assignment screen with progress indicator
- [ ] Rider: driver assigned screen (ETA, driver profile, car details)
- [ ] Driver: fleet ride assignment notification handler + accept/decline screen
- [ ] Digital receipt screen (extend existing ride completion flow)

**Integration Points:**
- Reuse `RidesService` base patterns; fleet rides are a superset
- Reuse `StripePaymentService` for capturing payment; extend for Transfer step
- Reuse `NotificationService` for push (driver assignment) + `EmailService` (receipt)
- Reuse `GooglePlacesService` for distance/ETA calculations

---

### Phase 4 — Dashboard, Analytics & Launch QA (Weeks 7–8)

**Backend:**
- [ ] `FleetAnalyticsService`: aggregate rides, earnings, driver performance for 30/60/90-day windows
- [ ] Payout history endpoint
- [ ] Platform Admin analytics: fleet-level revenue, fee capture totals
- [ ] Notification throttling for high-reassignment scenarios

**Frontend:**
- [ ] Fleet Manager dashboard (total rides, total earnings, active drivers, payout history charts)
- [ ] Driver performance sub-screen (rides completed, rating, earnings summary)
- [ ] Admin: fleet-level analytics panel
- [ ] Notification templates for all fleet events (invite, BGC result, ride assignment, payout)

**QA Checklist:**
- [ ] Fleet registration → approval → tribe creation end-to-end
- [ ] Driver invite → BGC → activation end-to-end
- [ ] Rider join tribe → book ride → assignment → 60s window → reassignment
- [ ] Payment capture → fee deduction → fleet payout → receipt
- [ ] Admin suspend fleet (rides halt, manager notified)
- [ ] Mixed-role user (fleet driver also a P2P driver): booking and assignment isolation

---

## Key Integration Points with Existing Code

| New Feature | Reuses Existing Code | File |
|---|---|---|
| Fleet Stripe Connect | `StripeConnectService` | `src/stripe/services/stripe-connect.service.ts` |
| Fleet tribe creation | `Community` entity + `CommunitiesService` | `src/communities/` |
| Driver BGC | `DriverApplicationService` pattern | `src/users/services/driver-application.service.ts` |
| Push notifications | `NotificationService` + `PushNotificationService` | `src/common/services/` |
| Email invites | `EmailService` | `src/common/services/email.service.ts` |
| Ride assignment timer | `RideExpirationService` + Redis | `src/rides/services/ride-expiration.service.ts` |
| Document upload | `UploadService` + S3 | `src/upload/` |
| Auth & role guards | `AuthGuard`, `RoleGuard` | `src/common/guards/` |
| Flutter DI | `get_it` + `injectable` | `lib/shared/domain/core/configs/injection.dart` |
| Flutter navigation | `NavigationService` + route names | `lib/shared/services/navigation_services/` |
| Flutter auth state | `AppStateNotifier` | `lib/app.dart` |

---

## New Role & Guard Matrix

| Role | Can Do |
|---|---|
| `fleet_manager` | Register fleet, invite drivers, manage roster, view fleet analytics, manage tribe membership |
| `driver` (fleet) | Accept invites, view fleet ride assignments, accept/decline rides |
| `rider` | Discover fleet tribes, join tribes, book fleet rides |
| `admin` | Approve/reject/suspend fleets, set platform fee, view all fleet analytics |

---

## Migration Order

1. `CreateFleetTable`
2. `CreateFleetDriverTable`
3. `CreateFleetInviteTable`
4. `AddFleetTribeTypeToCommunities`
5. `AddFleetIdToRides`
6. `AddFleetManagerRoleToUsers`

---

## Non-Goals (deferred per BRD)
- Real-time GPS dispatch / route optimization
- Direct driver payouts through Neighborly (fleet pays drivers off-platform)
- Multi-city / multi-region fleet operations
- White-label fleet app
- 3rd-party telematics
