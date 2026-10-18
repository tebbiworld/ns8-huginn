# ns8-huginn

A [NethServer 8](https://github.com/NethServer/ns8-core) module that packages
[Huginn](https://github.com/huginn/huginn) — a system for building agents that
monitor and act on your behalf.

The module runs two rootless containers inside a single Podman pod:

- **huginn-app** — the official `ghcr.io/huginn/huginn` image (web UI + background
  workers, runs database migrations on start)
- **huginn-db** — a dedicated `mariadb` database, data kept in the
  `huginn-mysql` named volume

Traefik publishes Huginn on the host name you configure, with optional Let's
Encrypt certificate and HTTP→HTTPS redirection. Outgoing email uses the cluster
smarthost automatically.

## Install

From the NethServer 8 cluster leader:

```bash
add-module ghcr.io/tebbiworld/huginn:latest 1
```

Then configure it (replace the host name):

```bash
api-cli run module/huginn1/configure-module --data '{
  "host": "huginn.example.org",
  "lets_encrypt": true,
  "http2https": true,
  "timezone": "Europe/Berlin"
}'
```

Read back the configuration, including the generated initial admin password:

```bash
api-cli run module/huginn1/get-configuration --data '{}'
```

Log in at `https://huginn.example.org` with user `admin` and the returned
password, then change it immediately.

## Advanced feature switches

Two security-sensitive Huginn capabilities are exposed as module options. Both
default to `false` (the safe state) and can be toggled from the **Settings** page
in the Cockpit UI or via `configure-module`. Changing either one restarts the
Huginn container so the new value takes effect.

- **`enable_insecure_agents`** — unlocks the `ShellCommandAgent` and
  `LocalFileAgent`, which can run arbitrary shell commands and read/write files
  on the server. **Security risk:** only enable this on a trusted, single-tenant
  instance whose users you fully trust.
- **`enable_second_precision_schedule`** — allows second-level fields in the
  `SchedulerAgent` cron expression. By default schedules are limited to minute
  precision. (The scheduler already ticks a few times per second, so no other
  change is needed for sub-minute schedules to fire.)

## Registration, email confirmation and AI

- **`invitation_code`** — the code required to register a new account. Huginn's
  built-in default (`try-huginn`) is public, so the module generates a **random**
  code on install to block unwanted self-registration. Read or change it on the
  Settings page (the page shows only that a code is stored, type a new one to
  change it) and hand it out to the users who should be allowed to sign up.
  Leaving the field empty keeps the current code. There is no way to set this
  from inside Huginn itself — it is a boot-time environment variable.
- **`require_confirmed_email`** — when on, new users must confirm their email
  address before they can log in. Requires a working mail relay (cluster
  smarthost or the manual SMTP settings above).
- **`openai_api_key`** / **`openai_base_url`** — global fallback credentials for
  the built-in OpenAI agents (LLM, image, speech, video). The key can also be set
  per agent. Point `openai_base_url` at a compatible endpoint (e.g.
  `http://host:11434/v1` for Ollama); leave it empty for OpenAI itself. An empty
  key field keeps the stored key; `openai_api_key_remove` deletes it.

```bash
api-cli run module/huginn1/configure-module --data '{
  "host": "huginn.example.org",
  "enable_insecure_agents": false,
  "enable_second_precision_schedule": true,
  "invitation_code": "s3cr3t-invite",
  "require_confirmed_email": true,
  "openai_api_key": "sk-...",
  "openai_base_url": "https://api.openai.com/v1"
}'
```

## Background workers and health check

Huginn runs agents in background jobs (Delayed Job). When the database stalls
for longer than the job time limit - heavy disk load during a backup is enough -
a job is aborted inside a query and the worker can stay stuck for good: the web
UI and webhooks keep working, but no agent runs, nothing is forwarded or mailed,
and nothing reports it. The module therefore offers:

- **`delayed_job_max_runtime`** (minutes, 2-60, default **15**; Huginn's own
  default is 2) - time limit of one agent run. Installations from before 1.4.0
  get 15 with the update.
- **`delayed_job_workers`** (1-5, default 1) - agents running in parallel, each
  worker needs about 300 MB RAM. **`delayed_job_sleep_delay`** (seconds) and
  **`database_pool`** (connections per process) are available too.
- **Health check** - a timer checks the job table every 5 minutes. Jobs due for
  longer than `healthcheck_minutes` (default 30) count as overdue; from
  `healthcheck_backlog` overdue jobs (default 20) or a job lock older than the
  time limit the worker is considered stuck. `healthcheck_mode`:
  - `restart` (default) - restart Huginn, the backlog is processed afterwards;
    alarms that refer to the outage may follow,
  - `quiet` - drop the queued jobs and move the mail agents (Email, Email
    digest, Timed email) past the events of the outage before the restart, so no
    stale alarms are sent; data agents still receive the events,
  - `off` - only a warning in the log.
  An optional `healthcheck_mail_to` gets a report through the cluster smarthost
  after an automatic restart. The settings page shows the backlog, failed jobs,
  the last restart and scheduled agents that have not run for more than 26 hours.

## Backup, restore and secrets

Before each backup run the module writes a consistent MariaDB dump
(`state/huginn.sql`) and exports every user's agents as scenario JSON
(`state/agents-export/agents.json`, the format of Huginn's own scenario export -
readable and importable scenario by scenario). The NS8 module backup contains
the dump, the export, the uploaded custom agents and `state/passwords.env`. On restore the module rebuilds the
database from the dump and re-applies all settings.

Passwords, tokens and keys (database, Rails secret token, initial admin
password, invitation code, OpenAI key, SMTP password) are stored in
`state/passwords.env`, mode 0600, and not in the module environment, which NS8
mirrors to Redis. The settings page never receives them: it only shows whether a
value is stored; the initial admin password is shown on request (action
`get-admin-password`).

Huginn has no directory (LDAP) login, so the module cannot join an NS8 user
domain.

## Build

```bash
bash build-images.sh
buildah push ghcr.io/tebbiworld/huginn:latest
```

## Uninstall

```bash
remove-module --no-preserve huginn1
```

## License

GPL-3.0-or-later
