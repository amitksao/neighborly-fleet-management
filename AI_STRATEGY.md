# AI Strategy — Neighborly Fleet Management
**Date:** 2026-05-20
**Status:** Draft — defines what "AI-based ride experience" means for v1, v1.5, and v2

---

## What "AI-Based Ride Experience" Means for This Product

The product is currently 100% rules-based. This document defines exactly which AI features to build, in what order, and what data must be collected to make them possible.

The strategy is graduated: start with deterministic improvements to dispatch quality (v1), introduce predictive models as data accumulates (v1.5), and deliver fully dynamic, learning-based features in v2.

---

## Phase 1 — Smarter Rules (v1 MVP, Buildable Now)

These features are not ML but are closer to "intelligent" than the current haversine-only dispatch. They require no training data.

### 1.1 Multi-Factor Driver Scoring

**Current:** Nearest driver by straight-line distance.

**Upgrade:** Score each active driver on four factors:

| Factor | Weight | Source |
|---|---|---|
| Proximity (haversine km) | 40% | Driver's `lastLocation` |
| Historical acceptance rate | 25% | `FleetDriver.completed_rides / assigned_rides` |
| Driver rating | 20% | `FleetDriver.rating` (to be added to entity) |
| Hours on shift today | 15% | `FleetDriver.shift_start` (to be added) |

Implementation: replace `selectBestDriver` in `fleet-ride.service.ts` with a scoring function. All inputs are available from the database — no external model needed.

**Effort:** 1 day. **Value:** Higher acceptance rate, fewer reassignment cycles.

### 1.2 Route-Based Fare Estimation (Pre-Booking)

**Current:** Fare is 0 at booking. Rider books blind.

**Upgrade (already implemented in P0):** `GET /fleet/rides/estimate` returns distance, duration, and estimated fare before booking. The booking screen now shows this estimate.

**v1 pricing formula:**
```
fare = base_fare + (rate_per_km × distance_km) + (rate_per_min × duration_min)
```
Rates stored per-fleet in the `Fleet` entity (requires schema addition).

**Effort:** 1 day for schema + pricing engine. **Value:** P0 — rider can make an informed decision.

### 1.3 Demand-Aware Assignment Timeout

**Current:** Fixed 60-second window for all assignments regardless of time of day.

**Upgrade:** Shorten the acceptance window during high-demand periods (detected by rides-in-flight count in Redis) to reduce rider wait time. Extend it during low-demand periods to avoid premature reassignment.

**Effort:** Half day. **Value:** Reduces cancellations during peak demand.

---

## Phase 2 — Predictive Features (v1.5, Requires 4+ Weeks of Data)

These features require historical ride data for training. Instrument data collection from day 1 of production.

### 2.1 Demand Forecasting

**What:** Predict ride volume by (fleet, hour_of_day, day_of_week) to suggest pre-positioning of drivers.

**Model:** Time-series regression (Prophet or ARIMA) over `fleet_rides` grouped by fleet, scheduled_at hour.

**Output to fleet manager:** "Expect high demand Saturday 5-7pm. Consider activating 3 additional drivers."

**Data required:** 4+ weeks of ride history per fleet before model has meaningful signal.

**Effort:** 2 weeks (model + API endpoint + dashboard widget).

### 2.2 Driver Acceptance Prediction

**What:** Before assigning a driver, predict probability they will accept.

**Model:** Logistic regression on (driver_id, hour_of_day, day_of_week, pickup_zone, recent_shift_hours).

**Use:** Skip drivers with acceptance probability < 30% to reduce timeout cycles.

**Data required:** 500+ assignment events per driver.

**Effort:** 3 weeks (feature engineering + model + integration).

### 2.3 ETA Confidence Intervals

**Current:** Single duration string from Google Places (static).

**Upgrade:** Supplement Google Places ETA with a correction factor trained on (scheduled_eta vs actual_duration) from completed fleet rides. Show rider "13–18 min" instead of "15 min".

**Data required:** 200+ completed rides with both `estimated_duration` and `completed_at` timestamps.

**Effort:** 2 weeks.

---

## Phase 3 — Dynamic Optimization (v2)

### 3.1 Surge Pricing

**Trigger:** When active ride requests > 1.5× active available drivers for a fleet, apply a demand multiplier to fare.

**Model:** Supply/demand ratio is rules-based; the multiplier curve is tuned via A/B testing.

**Requires:** Fare engine (Phase 1), real-time supply/demand tracking in Redis.

**Effort:** 2 weeks.

### 3.2 Personalized Rider Experience

- Saved places (home, work) stored per rider
- Suggested pickup time based on rider's historical booking times
- Preferred driver (if rider has rated a driver 5★ multiple times)

**Effort:** 3 weeks for backend + UI.

### 3.3 Operations Intelligence Dashboard

Fleet manager alerts:
- "Driver X has declined 4 of their last 5 assignments"
- "Your revenue this week is 30% below last week's same days"
- "Tuesday 6–8pm consistently under-served — consider recruiting 2 more drivers"

**Effort:** 3 weeks.

---

## Data Instrumentation (Start Immediately)

The following events must be logged to enable Phase 2 ML. Add a `fleet_events` table or emit to a data warehouse on day 1 of production:

| Event | Fields |
|---|---|
| `ride.assigned` | rideId, fleetId, driverId, attempt, pickupLat, pickupLng, scheduledAt |
| `ride.accepted` | rideId, driverId, latencyMs (time from assigned to accepted) |
| `ride.declined` | rideId, driverId, reason (if known) |
| `ride.completed` | rideId, actualDurationMin, estimatedDurationMin, fareActual, fareEstimated |
| `ride.cancelled` | rideId, reason, attempt |
| `driver.shift_start` | driverId, fleetId, timestamp |
| `driver.shift_end` | driverId, fleetId, timestamp |

---

## v1 Decision: What Is "AI" for Launch?

For the initial product launch, "AI-based ride experience" means:

1. **Multi-factor driver scoring** (Phase 1.1) — replaces haversine-only with a scored model
2. **Pre-booking fare estimation** (Phase 1.2) — already built in P0
3. **Demand-aware timeout** (Phase 1.3) — simple but intelligent

These three features, combined with the data instrumentation above, constitute a credible v1 AI story and lay the foundation for Phase 2 as data accumulates.

The product should NOT be marketed as having ML/predictive AI until Phase 2 models are trained and deployed.
