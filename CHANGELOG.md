# Changelog

## 1.3.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Secrets moved out of the module environment.** The database passwords, the Rails secret token, the initial admin password, the invitation code, the OpenAI API key and the SMTP password are now kept in `state/passwords.env` (mode 0600) instead of `state/environment`, which NS8 mirrors to Redis in plain text. Existing installations are migrated on update; the values do not change. The secrets are no longer passed on the podman command line, and the generated `smarthost.env` is private too.
- **Module backup now contains the data.** New `etc/state-include.conf`: the backup holds a consistent MariaDB dump written by `module-dump-state`, the secrets file and the uploaded custom agents. Before, only the module environment was saved.
- **Working restore.** New `restore-module` steps rebuild the database from the dump and re-apply every setting.
- MariaDB pinned to `11.4.12` instead of the rolling `11.4` tag.
- Service restarts list every unit of the pod explicitly.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

### Platform integration

- **Clone and move.** New `clone-module` step (a link to the restore step): a cloned or moved instance gets its route and settings back instead of coming up unconfigured.
- Release notes are linked from the software centre (`relnotes_url`).

## 1.2.2 — 2026-09-14

### Changed

- Runtime image pinned to the Huginn release `v2026.09.09` instead of the moving `latest` (master) tag: every installation now runs the same version; new releases arrive as module updates (automatic every ~6 weeks).

All notable changes to this module are documented here. Releases before 1.2.1
are described in the GitHub release notes and the git history.

## 1.2.1

### Fixed

- **Time zone had no effect on schedules.** The Settings field was only passed
  to the container as `TZ`, which configures glibc. Huginn/Rails reads the time
  zone from `TIMEZONE` only (`config/application.rb`, `lib/huginn_scheduler.rb`)
  and therefore kept using its built-in default `Pacific Time (US & Canada)`, so
  a `6am` schedule fired at 15:00 Central European Summer Time. The application
  unit now passes the configured zone as both `TZ` and `TIMEZONE`.
  Verified against the image: Rails 8.1 accepts IANA identifiers such as
  `Europe/Berlin` directly, so no name mapping is needed.

### Added

- Configure-module rejects an unknown time zone (validated against the IANA
  database) instead of letting the container fail to start with
  `ArgumentError: Invalid Timezone`.
- Settings page shows a note about publishing Huginn through a gateway node:
  the gateway route must target `https://<worker-VPN-address>` with certificate
  verification skipped, and Let's Encrypt and HTTP→HTTPS redirection stay off on
  the worker. Otherwise `X-Forwarded-Proto` is downgraded to http and the login
  POST fails with a CSRF error.
- The update hook seeds `TZ=UTC` on instances where it is unset, so `TIMEZONE`
  is never empty after the upgrade.
