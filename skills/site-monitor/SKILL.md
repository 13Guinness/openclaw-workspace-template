---
name: site-monitor
description: Monitor uptime and SSL certificate expiry for client websites. Check site availability, response times, and SSL expiry dates. Alerts when sites are down or certs expire within 30 days.
version: 1.0
category: monitoring
---

# Site Monitor

Monitor uptime and SSL certificate expiry for client websites. Get instant visibility into site availability, response times, and SSL certificate health across your entire client portfolio.

## Quick Start

```bash
# Add a site
bash ~/.openclaw/workspace/skills/site-monitor/scripts/add-site.sh "FuelVM" "https://fuelvm.com"

# Run a check
bash ~/.openclaw/workspace/skills/site-monitor/scripts/check-sites.sh
```

---

## Managing Sites

### Adding a Site

```bash
bash ~/.openclaw/workspace/skills/site-monitor/scripts/add-site.sh "Site Name" "https://example.com"
```

Sites are saved to:
```
~/.openclaw/workspace/skills/site-monitor/config/sites.json
```

Format:
```json
[
  {"name": "FuelVM", "url": "https://fuelvm.com"},
  {"name": "Client Acme", "url": "https://acme.com"}
]
```

### Removing a Site

Edit the config file directly and delete the relevant JSON object:

```bash
# Open in default editor
open ~/.openclaw/workspace/skills/site-monitor/config/sites.json

# Or edit in terminal
nano ~/.openclaw/workspace/skills/site-monitor/config/sites.json
```

Remove the line for the site you want to stop monitoring, keeping valid JSON (no trailing commas).

---

## Running Checks

### Manual Check

```bash
bash ~/.openclaw/workspace/skills/site-monitor/scripts/check-sites.sh
```

### Scheduled Checks via OpenClaw Cron

Set up periodic monitoring using OpenClaw's cron system:

```bash
# Every hour
openclaw cron add "site-monitor-hourly" "0 * * * *" \
  "bash ~/.openclaw/workspace/skills/site-monitor/scripts/check-sites.sh"

# Every 5 minutes
openclaw cron add "site-monitor-frequent" "*/5 * * * *" \
  "bash ~/.openclaw/workspace/skills/site-monitor/scripts/check-sites.sh"

# Daily at 8am
openclaw cron add "site-monitor-daily" "0 8 * * *" \
  "bash ~/.openclaw/workspace/skills/site-monitor/scripts/check-sites.sh"
```

---

## Understanding Check Output

Example output:

```
Site Monitor — 2024-03-15 09:30:00
----------------------------------------------------------------------
SITE                   STATUS        CODE    TIME        SSL
----------------------------------------------------------------------
FuelVM                 ✅ UP         200     245ms       87d
Acme Corp              ✅ UP         200     312ms       42d
Pending Renewal        ⚠️  WARN      200     198ms       22d [WARN]
Almost Expired         🚨 CRIT       200     155ms       4d [CRIT]
Offline Client         ❌ DOWN       000     —           —
----------------------------------------------------------------------

Summary:  4/5 up  |  1 DOWN  |  1 SSL critical  |  1 SSL expiring soon
```

### Column Reference

| Column | Description |
|--------|-------------|
| SITE   | Site name from `sites.json` (truncated to 20 chars) |
| STATUS | Overall health: ✅ UP / ❌ DOWN / ⚠️ WARN / 🚨 CRIT |
| CODE   | HTTP response code. `000` means no connection at all |
| TIME   | Total response time in milliseconds |
| SSL    | Days until SSL certificate expires (https sites only) |

### Status Icons

| Icon | Meaning |
|------|---------|
| ✅ UP   | Site reachable, SSL healthy (≥ 30 days) |
| ❌ DOWN | Unreachable or error response |
| ⚠️ WARN | Site up, SSL expires in < 30 days |
| 🚨 CRIT | Site up, SSL expires in < 7 days |

---

## Alert Thresholds

| Condition | Threshold | Severity |
|-----------|-----------|----------|
| Site unreachable or error | Any failure | ❌ DOWN — act immediately |
| HTTP 4xx / 5xx response | Any error code | ❌ DOWN |
| SSL certificate expiry | < 30 days remaining | ⚠️ WARN |
| SSL certificate expiry | < 7 days remaining | 🚨 CRIT |
| SSL certificate expiry | ≥ 30 days remaining | ✅ OK |

> **Note:** HTTP redirects (301/302) followed automatically via `curl -L`. A redirect chain that resolves to a 2xx is counted as UP.

---

## What To Do When a Site Is DOWN

1. **Verify independently** — visit the URL in a browser or check from another network/device.

2. **Read the HTTP code:**
   - `000` — DNS failure or server completely unreachable. Check DNS records and hosting provider status.
   - `5xx` — Server-side error. Check server logs or contact hosting provider.
   - `4xx` — Client error. Verify the URL is correct (may have moved or require auth).
   - `301/302` — Redirect loop or broken redirect chain. Update the URL in `sites.json` to the final destination.

3. **Check hosting provider status pages** for known outages.

4. **SSH into the server** if you have access:
   ```bash
   systemctl status nginx       # check web server
   journalctl -u nginx -n 50   # recent logs
   df -h                        # disk space (full disk = server errors)
   free -m                      # memory pressure
   ```

5. **Escalate or notify** the client if the issue cannot be resolved quickly.

---

## What To Do About SSL Warnings

### ⚠️ WARN — Less than 30 days remaining

- Schedule renewal soon. Most CAs send reminder emails — check the domain admin inbox.
- If using Let's Encrypt: run `sudo certbot renew` on the server.
- If using cPanel: use the SSL/TLS Manager auto-renew feature.

### 🚨 CRIT — Less than 7 days remaining

Renew immediately. Browser security warnings will appear for visitors once the cert expires.

**Let's Encrypt (Certbot):**
```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx   # or apache2
```

**Verify renewal:**
```bash
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null \
  | openssl x509 -noout -dates
```

**Paid certificate:** Purchase and install a new cert via your registrar or CA, then restart the web server.

---

## Dependencies

| Tool | Purpose | Included with macOS |
|------|---------|---------------------|
| `curl` | HTTP checks and response timing | Yes |
| `openssl` | SSL certificate expiry | Yes |
| `python3` | JSON parsing and float math | Yes (macOS 12.3+) |

If `python3` is missing, install via [python.org](https://python.org) or Homebrew: `brew install python`.
