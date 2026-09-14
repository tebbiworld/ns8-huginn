# Changelog

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
