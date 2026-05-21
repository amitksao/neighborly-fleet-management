#!/usr/bin/env bash
# sync-fleet-to-backend.sh
#
# Applies fleet module updates from neighborly-fleet-management
# into the neighborly_backend before deploying.
#
# Run from anywhere:
#   bash neighborly-fleet-management/scripts/sync-fleet-to-backend.sh
#
# What it does:
#   1. Rewrites import paths from relative (../../../../../src/) to NestJS aliases (src/)
#   2. Copies updated fleet service/controller files into neighborly_backend/src/fleet/
#   3. Copies any new migrations

set -euo pipefail

FLEET_SRC="$(cd "$(dirname "$0")/.." && pwd)/backend/src/fleet"
BACKEND_FLEET="$(cd "$(dirname "$0")/../../neighborly-backend/neighborly_backend/src/fleet" && pwd)"
FLEET_MIGRATIONS="$(cd "$(dirname "$0")/.." && pwd)/backend/src/database/migrations"
BACKEND_MIGRATIONS="$(cd "$(dirname "$0")/../../neighborly-backend/neighborly_backend/src/database/migrations" && pwd)"

echo "=== Fleet Module Sync ==="
echo "Source : $FLEET_SRC"
echo "Target : $BACKEND_FLEET"
echo ""

# ── 1. Copy fleet service and controller files, fixing import paths ──────────
sync_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"

  # Rewrite relative paths (../../../../src/ and ../../../../../src/) → src/
  sed \
    -e "s|'\.\./\.\./\.\./\.\./\.\./src/|'src/|g" \
    -e "s|'\.\./\.\./\.\./\.\./src/|'src/|g" \
    "$src" > "$dest"

  echo "  synced: $(basename "$src")"
}

echo "Syncing controllers..."
for f in "$FLEET_SRC"/controllers/*.ts; do
  sync_file "$f" "$BACKEND_FLEET/controllers/$(basename "$f")"
done

echo "Syncing services..."
for f in "$FLEET_SRC"/services/*.ts; do
  sync_file "$f" "$BACKEND_FLEET/services/$(basename "$f")"
done

echo "Syncing entities..."
for f in "$FLEET_SRC"/entities/*.ts; do
  sync_file "$f" "$BACKEND_FLEET/entities/$(basename "$f")"
done

echo "Syncing DTOs..."
for f in "$FLEET_SRC"/dto/*.ts; do
  sync_file "$f" "$BACKEND_FLEET/dto/$(basename "$f")"
done

echo "Syncing guards..."
for f in "$FLEET_SRC"/guards/*.ts; do
  sync_file "$f" "$BACKEND_FLEET/guards/$(basename "$f")"
done

if [ -f "$FLEET_SRC/fleet.module.ts" ]; then
  sync_file "$FLEET_SRC/fleet.module.ts" "$BACKEND_FLEET/fleet.module.ts"
fi

# ── 2. Copy new migrations ───────────────────────────────────────────────────
echo ""
echo "Syncing migrations..."
for f in "$FLEET_MIGRATIONS"/*.ts; do
  dest="$BACKEND_MIGRATIONS/$(basename "$f")"
  if [ ! -f "$dest" ]; then
    cp "$f" "$dest"
    echo "  new migration: $(basename "$f")"
  else
    echo "  skipped (exists): $(basename "$f")"
  fi
done

echo ""
echo "=== Sync complete. ==="
echo ""
echo "Next steps:"
echo "  1. cd neighborly-backend/neighborly_backend"
echo "  2. Review the changed files: git diff src/fleet/"
echo "  3. Run migrations:  npm run typeorm migration:run"
echo "  4. Build:           npm run build"
echo "  5. Push to trigger Railway deploy"
