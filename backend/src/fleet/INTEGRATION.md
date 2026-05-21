# Fleet Module — Integration Guide

## Already done (applied directly to neighborly_backend)
- `Community` entity: `type`, `fleet_id`, `is_public`, `auto_approve_riders` fields added
- `Ride` entity: `fleet_id`, `assignment_attempts`, `fleet_payout_transfer_id`, `platform_fee_amount` fields added
- `NotificationType` enum: all fleet notification types added
- `pubspec.yaml`: `http: ^1.2.0` added

## 1. Register FleetModule in app.module.ts

```typescript
// neighborly_backend/src/app.module.ts
import { FleetModule } from './fleet/fleet.module';   // ← add

@Module({
  imports: [
    // ... existing imports ...
    FleetModule,   // ← add
  ],
})
export class AppModule {}
```

## 2. Run migrations in order

```bash
npm run typeorm migration:run
```

Migration order (timestamps enforce this automatically):
1. `1748200000001-CreateFleetTable`
2. `1748200000002-CreateFleetDriverTable`
3. `1748200000003-AddFleetTribeTypeToCommunities`
4. `1748200000004-AddFleetIdToRides`

Copy the four migration files from `neighborly-fleet-management/backend/src/database/migrations/`
into `neighborly_backend/src/database/migrations/`.

## 3. Add env variables

```env
APP_BASE_URL=https://neighborly.live            # Used in invite email links
BGC_WEBHOOK_SECRET=your_bgc_vendor_secret       # Shared secret for BGC vendor webhook callbacks
STRIPE_CONNECT_WEBHOOK_SECRET=whsec_...         # From Stripe dashboard → Webhooks → fleet/stripe/webhook endpoint
                                                # Events to listen for: account.updated
```

## 4. Copy fleet source into backend

Copy the entire `neighborly-fleet-management/backend/src/fleet/` directory
into `neighborly_backend/src/fleet/`.

Update import paths: replace `'../../../src/...'` with `'src/...'` throughout.

## 5. Register entities with TypeORM config

Ensure `typeorm.ts` / `ormconfig` includes the new entities:
```typescript
entities: [
  // ... existing ...
  Fleet,
  FleetDriver,
  FleetInvite,
],
```

Or use the glob pattern `src/**/*.entity.ts` if already configured.
