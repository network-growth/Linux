#!/usr/bin/env bash
set -euo pipefail

SRC="/opt/club/club.db"
DEST="/var/backups/club"
KEEP_DAYS=7

mkdir -p "$DEST"
cp "$SRC" "$DEST/club-$(date +%F-%H%M).db"
find "$DEST" -name 'club-*.db' -mtime +"$KEEP_DAYS" -delete
