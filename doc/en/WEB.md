---
name: web-en
description: Installation, access, and interface reference for the local web controller
metadata:
  version: "1.0.0"
  lang: "en"
---

# Web Guide

## Multilingual

[简体中文](../WEB.md) | **English** | [Español](../es/WEB.md)

## Scope

This guide describes the local web controller in the current source, its installation, and access methods. It does not guarantee that older release packages include all current source fixes.

## Build and Install

Execute in the root of reviewed source code:

```bash
cd src/web
npm ci
npm run check
cd ../..
sudo bash deploy/install.sh
```

Building requires Node.js 22.12+ or 24+ and npm 10+. Running the service requires Python 3.10+, SMART, and block device tools. The installer supports only Debian running systemd, installs missing runtime dependencies, places the application in `/root/apps/hdd-health-check`, places the unit in `/etc/systemd/system/hdd-health-web.service`, and enables a password-protected service on TCP 8765. Host state and logs are preserved.

Access `http://<NAS-IP>:8765` from a trusted LAN and log in with the `web-password` read from the host by an administrator. HTTP does not encrypt credentials; do not expose this port to the internet. The service can also be accessed via SSH tunnel. The service validates the target Host and same-origin Origin; it does not grant access based on arbitrary forwarding headers.

Manual run for development only:

```bash
sudo python3 src/web/server.py --bind 127.0.0.1 --port 8765
```

This mode listens only on loopback; when no password file is provided, local access mode is used. Non-loopback bindings require `--password-file` pointing to a root-owned regular file with restricted permissions. The LAN unit provided by the installer always passes a password file.

## Pages and Permissions

| Page | Purpose |
| --- | --- |
| `/disks` | Dashboard, capacity, disk cards, and batch checks |
| `/disks/<device>`, `/attention/<device>` | SMART detail, detection results, serial number display, and supported disk power operations |
| `/attention` | Anomaly evidence and records requiring re-check |
| `/tasks` | Current tasks, completed/stopped/failed receipts, and available logs |
| `/schedule` | Schedule configuration for a quick check every 6–168 hours |
| `/settings` | Language, light/dark mode, eight theme colors, sleep policy, and security entry |
| `/security` | Administrator password update and IP access control |
| `/changelog` | Build identifier and official changes, readable before login |

Password login establishes a session. Security APIs require a five-minute password verification saved by the server for that session; changing the password invalidates existing sessions. IP access accepts only exact RFC 1918 IPv4 or `fc00::/7` addresses and grants only ordinary permissions; entering security settings requires re-verification of the password. Removing an allowed address immediately revokes its access. The browser clears IP access records after logout or rejection.

Pages navigate immediately. Settings sections scroll only to the corresponding card; security entry performs separate verification. Private serial numbers are masked by default; the reveal operation fetches the original via a separate authenticated API; switching tabs or leaving the detail view restores masking. The UI provides eight languages; documentation changelogs provide Simplified Chinese/English/Spanish; other languages fall back to English.

## Checks and Data Boundaries

Batch requests select disks on the server based on the current device inventory and scope; only fixed modules are accepted. SSDs support quick check, short test, long test, surface scan, and full assessment; mixed selections skip SSDs for HDD-specific checks. Web calls append `--no-install` and do not auto-approve system package installation.

Once enabled, schedule configuration continues to be saved and executed; update installations do not reset it. Stopping the web service does not equal stopping independent systemd checks; requesting a safe stop via the page or CLI still does not cancel disk-internal self-tests.

Raw SMART health status, temperature, and counters do not substitute for a batch composite score. Missing fields remain unknown; vendor counter units are not guessed. Host logs and trend data may contain device identifiers; deleting the last SMART sample changes the next comparison baseline.

## API

Except for auth status and static pages, the API requires valid access. In password-authenticated mode, JSON requests that change state also require `X-HDD-CSRF: 1`; security-related paths additionally check recent password permissions.

| Path | Responsibility |
| --- | --- |
| `GET /api/auth`, `POST /api/auth/login`, `/ip-login`, `/logout` | Access status and sessions |
| `POST /api/auth/security-verify`, `/change-password` | Recent verification and password update |
| `GET/POST /api/access` | Protected IP allowlist and toggle |
| `GET /api/build`, `/api/changelog?lang=<lang>` | Build-embedded version and corresponding changelog |
| `GET /api/snapshot`, `/api/disks/<device>/smart`, `/serial` | Disk snapshot, SMART, and on-demand serial number |
| `POST /api/disks/<device>/wake`, `/sleep`, `/api/disks/wake-on-visit` | Supported single-disk or wake-on-visit operations |
| `GET/POST /api/preferences`, `/api/schedule` | Sleep preferences and schedule configuration |
| `POST /api/jobs`, `/api/jobs/assess`, `/api/jobs/stop` | Checks, batch assessment, and safe stop |
| `GET /api/status`, `/api/jobs/history`, `/api/jobs/history/<id>` | Current tasks, history receipts, and bounded log tail |
| `GET /api/history/<device>`, `/api/history/samples` | SMART trend data |
| `DELETE /api/jobs/history/<id>`, `/api/history/samples/<device>/<index>` | Delete receipt/associated log or single trend sample |

`/api/jobs/assess` accepts scope `sata,hdd,ssd,nvme,all` and modules `quick,short,long,speed,surface,badblocks,iface,full`. Arbitrary commands submitted by the browser are not accepted. A run return code of `1` or `2` indicates completion with issues found, not a task launch failure.

## Upgrade and Rollback

1. Finish or stop checks first and back up private state and logs; verify the current version and service unit.
2. Update and build the source, then re-run the installer. It preserves the password, old application, and matching unit backups, and attempts recovery on launch failure; package installation itself is not part of the application file rollback scope.
3. Check service active status, password login, `/api/build`, and disk inventory. Do not substitute page inspection for a full device assessment.

When a rollback is needed, first stop the service and independent checks, restore matching application, unit, and state backups that need to be reverted, run `sudo systemctl daemon-reload`, then start the service. Do not blindly delete or overwrite the state directory. Actual NAS updates and restart recovery still require target host verification.

## Development Verification

Run `bash scripts/check.sh` from the source root. In `src/web/`, run `npm run check`, install Playwright Chromium, then run `npm run test:ui`. Browser tests use an isolated session service and synthetic devices; they verify version, language fallback, responsive layout, permission display, keyboard, and simulated touch; they do not start real checks.
