# k3s datastore maintenance

Host-level maintenance job for `philip-homelab`. **Not deployed by Flux** — this
runs directly on the node via systemd, outside the cluster, because its job is
to stop k3s itself (a Kubernetes CronJob can't do that: the apiserver has to be
up to schedule the job, and the kubelet that manages the job's pod dies the
moment k3s stops).

## Why this exists

k3s's embedded SQLite datastore (`kine`) accumulates a revision row on every
write. Compaction is supposed to prune old revisions automatically, but on a
disk that can't keep up (this node's root volume is a spinning HDD) compaction
falls behind, the table grows unbounded, and every query gets slower — which
makes compaction fall further behind. Left unchecked this snowballs into the
apiserver timing out entirely (`context deadline exceeded`).

This job stops k3s, verifies the datastore isn't corrupt (`PRAGMA
integrity_check`), runs `VACUUM` to reclaim space and rebuild the table, then
restarts k3s — on a weekly schedule so bloat never has room to compound.

## Files

- `k3s-db-maintenance.sh` → installed to `/usr/local/sbin/`
- `k3s-db-maintenance.service` / `.timer` → installed to `/etc/systemd/system/`

## Install

```bash
sudo install -m 755 k3s-db-maintenance.sh /usr/local/sbin/k3s-db-maintenance.sh
sudo install -m 644 k3s-db-maintenance.service /etc/systemd/system/
sudo install -m 644 k3s-db-maintenance.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now k3s-db-maintenance.timer
```

Runs Sundays 03:00 (+ up to 10min random delay), logs to
`/var/log/k3s-db-maintenance.log`. Check status with:

```bash
systemctl list-timers k3s-db-maintenance.timer
```

## Real fix

This mitigates the symptom. The actual root cause is the datastore living on
a slow spinning disk — moving `/var/lib/rancher/k3s/server/db` to an SSD is
the fix that makes this job mostly unnecessary.
