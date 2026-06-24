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
