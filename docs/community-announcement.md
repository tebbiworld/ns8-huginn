<!--
First community post for the NS8 Huginn module, written in the style
of https://community.nethserver.org/t/ns8-forgejo-testing/28554 (first post).
Paste into a new topic on community.nethserver.org, category "App", tag "ns8".
Fill in the wiki link once the page is published.
-->

# NS8 Huginn (testing)

Hi all,

I've built an NS8 module for [Huginn](https://github.com/huginn/huginn) — a system for building agents that monitor the web and act on your behalf, a bit like your own self-hosted IFTTT/Zapier.

It's in my community repository. To try it, add the repo once:

```
api-cli run add-repository --data '{"name":"tebbiworld","url":"https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/","status":true,"testing":false}'
```

then install **Huginn** from the Software Center. (Or straight from the image: `add-module ghcr.io/tebbiworld/huginn:latest 1`.)

What it does:

* Runs Huginn (the Ruby on Rails web UI plus its background workers) with its own dedicated MariaDB database, all as rootless containers in a single pod.
* Lets you build agents that watch websites, feeds, webhooks and APIs and then react — scrape, notify, post, run schedules, chain events together.
* Published on an FQDN through Traefik with optional Let's Encrypt and HTTP→HTTPS redirection; outgoing email uses the cluster smarthost automatically.
* Generates a random registration invitation code on install (so the well-known public default can't be used to sign up), and can require email confirmation for new accounts.
* Optional global OpenAI-compatible credentials for the built-in LLM agents — point them at OpenAI or at a compatible endpoint such as Ollama.

A few things to know:

* The database keeps its data in a named volume that survives container recreation; an initial `admin` password is generated at install and returned by `get-configuration` — change it on first login.
* A couple of powerful features are off by default for safety: the insecure agents (ShellCommandAgent / LocalFileAgent) can run arbitrary shell commands and touch files on the server, so only enable those on a trusted, single-tenant instance. Second-precision schedules are likewise opt-in. Toggling either restarts the Huginn container.

It's fresh and still in testing, so any feedback is welcome — if you wire up a few agents, I'd love to hear what works and what feels rough.

Docs: NethServer wiki (tebbiworld repository) · Source: [github.com/tebbiworld/ns8-huginn](https://github.com/tebbiworld/ns8-huginn)

Thanks!

*Category: App · Tags: ns8*
