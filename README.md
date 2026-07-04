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
  Settings page and hand it out to the users who should be allowed to sign up.
  Leaving the field empty keeps the current code. There is no way to set this
  from inside Huginn itself — it is a boot-time environment variable.
- **`require_confirmed_email`** — when on, new users must confirm their email
  address before they can log in. Requires a working mail relay (cluster
  smarthost or the manual SMTP settings above).
- **`openai_api_key`** / **`openai_base_url`** — global fallback credentials for
  the built-in OpenAI agents (LLM, image, speech, video). The key can also be set
  per agent. Point `openai_base_url` at a compatible endpoint (e.g.
  `http://host:11434/v1` for Ollama); leave it empty for OpenAI itself.

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
