#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

"""Health of the Huginn background worker, read straight from the database
(no Rails boot): the Delayed Job backlog, stale job locks and agents whose
last run is long ago. Used by bin/huginn-healthcheck and get-configuration.

A worker that hit "execution expired" inside a database query can keep its
connections busy for good (ActiveRecord::ConnectionTimeoutError): the web UI
and webhooks keep working, but no job runs any more and nothing reports it.
"""

import datetime
import json
import os
import subprocess

STATE_FILE = "healthcheck.json"
# notification agents that would mail stale alarms after a long stop
MAIL_AGENTS = ("Agents::EmailAgent", "Agents::EmailDigestAgent", "Agents::TimedEmailAgent")


def sql(statement, timeout=60):
    """Run SQL in the huginn-db container; rows as lists of strings."""
    cmd = ["podman", "exec", "-i", "huginn-db", "sh", "-c",
           'exec mariadb -u root --password="$MARIADB_ROOT_PASSWORD" -N -B huginn']
    out = subprocess.run(cmd, input=statement, capture_output=True, text=True, timeout=timeout, check=True).stdout
    return [line.split("\t") for line in out.splitlines() if line]


def app_started_at():
    """Start time of the running huginn-app container (UTC), or None."""
    try:
        out = subprocess.run(["podman", "inspect", "huginn-app", "--format", "{{.State.Running}} {{.State.StartedAt.Unix}}"],
                             capture_output=True, text=True, timeout=30, check=True).stdout.split()
    except (subprocess.SubprocessError, OSError):
        return None
    if len(out) != 2 or out[0] != "true":
        return None
    return datetime.datetime.fromtimestamp(int(out[1]), datetime.timezone.utc)


def measure(minutes, max_runtime):
    """Backlog older than `minutes`, stale locks, failed jobs, stale agents."""
    rows = sql(f"""
SELECT COUNT(*), COALESCE(TIMESTAMPDIFF(MINUTE, MIN(run_at), UTC_TIMESTAMP()), 0)
  FROM delayed_jobs WHERE failed_at IS NULL AND locked_at IS NULL
   AND run_at < UTC_TIMESTAMP() - INTERVAL {int(minutes)} MINUTE;
SELECT COUNT(*) FROM delayed_jobs WHERE failed_at IS NULL AND locked_at IS NOT NULL
   AND locked_at < UTC_TIMESTAMP() - INTERVAL {int(max_runtime) + 10} MINUTE;
SELECT COUNT(*) FROM delayed_jobs WHERE failed_at IS NOT NULL;
SELECT COUNT(*) FROM delayed_jobs WHERE failed_at IS NULL;
""")
    stale = sql("""
SELECT id, REPLACE(REPLACE(name, '\\t', ' '), '\\n', ' '), schedule,
       COALESCE(DATE_FORMAT(last_check_at, '%Y-%m-%dT%H:%i:%SZ'), '')
  FROM agents
 WHERE disabled = 0 AND deactivated = 0
   AND schedule IS NOT NULL AND schedule NOT IN ('never', 'every_2d', 'every_7d')
   AND created_at < UTC_TIMESTAMP() - INTERVAL 26 HOUR
   AND (last_check_at IS NULL OR last_check_at < UTC_TIMESTAMP() - INTERVAL 26 HOUR)
 ORDER BY last_check_at LIMIT 10;
""")
    return {
        "backlog": int(rows[0][0]),
        "oldest_minutes": int(rows[0][1]),
        "stale_locks": int(rows[1][0]),
        "failed_jobs": int(rows[2][0]),
        "queued_jobs": int(rows[3][0]),
        "stale_agents": [{"id": int(r[0]), "name": r[1], "schedule": r[2], "last_check_at": r[3]} for r in stale],
    }


def discard_backlog():
    """Drop the queued jobs and move the mail agents past the events of the
    outage, so a restart does not send alarms that are no longer true."""
    types = ", ".join(f"'{t}'" for t in MAIL_AGENTS)
    sql(f"""
DELETE FROM delayed_jobs WHERE failed_at IS NULL;
UPDATE agents SET last_checked_event_id = (SELECT m FROM (SELECT MAX(id) AS m FROM events) AS x)
 WHERE type IN ({types});
UPDATE agents SET memory = JSON_REMOVE(memory, '$.queue')
 WHERE type = 'Agents::EmailDigestAgent' AND JSON_VALID(memory) AND JSON_CONTAINS_PATH(memory, 'one', '$.queue');
""", timeout=300)


def load_state():
    try:
        with open(STATE_FILE) as fp:
            return json.load(fp)
    except (OSError, ValueError):
        return {}


def save_state(state):
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as fp:
        json.dump(state, fp)
    os.replace(tmp, STATE_FILE)
