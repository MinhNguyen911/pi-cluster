#!/bin/bash
set -euo pipefail

DB=/var/lib/rancher/k3s/server/db/state.db
LOG=/var/log/k3s-db-maintenance.log
LOCK=/run/k3s-db-maintenance.lock

exec 9>"$LOCK"
if ! flock -n 9; then
  echo "$(date -Is) already running, exiting" >> "$LOG"
  exit 0
fi

log() { echo "$(date -Is) $*" >> "$LOG"; }

log "=== starting maintenance ==="

if [ ! -f "$DB" ]; then
  log "no datastore found at $DB, skipping"
  exit 0
fi

SIZE_BEFORE=$(stat -c%s "$DB")
log "stopping k3s (db size before: $SIZE_BEFORE bytes)"
systemctl stop k3s

for i in $(seq 1 30); do
  systemctl is-active --quiet k3s || break
  sleep 1
done

if systemctl is-active --quiet k3s; then
  log "ERROR: k3s did not stop, aborting maintenance"
  exit 1
fi

log "running integrity_check"
CHECK=$(sqlite3 "$DB" "PRAGMA integrity_check;")
if [ "$CHECK" != "ok" ]; then
  log "INTEGRITY CHECK FAILED: $CHECK -- skipping VACUUM, restarting k3s untouched"
  systemctl start k3s
  exit 1
fi

log "running VACUUM"
sqlite3 "$DB" "VACUUM;"

SIZE_AFTER=$(stat -c%s "$DB")
log "db size after: $SIZE_AFTER bytes (reclaimed $((SIZE_BEFORE - SIZE_AFTER)) bytes)"

log "starting k3s"
systemctl start k3s

for i in $(seq 1 30); do
  systemctl is-active --quiet k3s && break
  sleep 1
done

if systemctl is-active --quiet k3s; then
  log "k3s restarted OK"
else
  log "WARNING: k3s did not report active after restart -- check manually"
fi

log "=== maintenance complete ==="
