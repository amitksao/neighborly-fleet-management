#!/usr/bin/env bash
# sync-to-backend.sh
# Copies the latest fleet module from neighborly-fleet-management into neighborly_backend.
# Run this before every deployment to ensure the backend has the latest fleet code.
#
# Usage (from repo root):
#   bash neighborly-fleet-management/scripts/sync-to-backend.sh

set -euo pipefail

FLEET_SRC="$(dirname "$0")/../backend/src/fleet"
BACKEND_DEST="$(dirname "$0")/../../neighborly-backend/neighborly_backend/src/fleet"

echo "Syncing fleet module..."
echo "  From: $FLEET_SRC"
echo "  To:   $BACKEND_DEST"

# Copy all fleet source files, preserving structure
rsync -av --delete \
  --exclude="*.spec.ts" \
  --exclude="node_modules" \
  --exclude="*.js" \
  --exclude="*.d.ts" \
  "$FLEET_SRC/" "$BACKEND_DEST/"

echo ""
echo "Done. Fleet module synced to backend."
echo ""
echo "Next: copy fleet migrations if new ones were added:"
echo "  From: $(dirname "$0")/../backend/src/database/migrations/"
echo "  To:   $(dirname "$0")/../../neighborly-backend/neighborly_backend/src/database/migrations/"
