#!/bin/bash
# check-sites.sh — Check uptime and SSL for all monitored sites
# macOS bash 3.2 compatible

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITES_FILE="$SCRIPT_DIR/../config/sites.json"

if [ ! -f "$SITES_FILE" ]; then
  echo "❌ No sites.json found at $SITES_FILE"
  exit 1
fi

SITE_COUNT=$(python3 -c "import json; data=json.load(open('$SITES_FILE')); print(len(data))")

if [ "$SITE_COUNT" -eq 0 ]; then
  echo "ℹ️  No sites configured. Add one with: ./add-site.sh --name 'My Site' --url 'https://example.com'"
  exit 0
fi

echo ""
echo "🔍 Checking $SITE_COUNT site(s)..."
echo ""
printf "%-30s %-8s %-10s %-12s %s\n" "SITE" "STATUS" "HTTP" "RESP (ms)" "SSL DAYS"
printf "%-30s %-8s %-10s %-12s %s\n" "----" "------" "----" "---------" "--------"

ALERTS=""

python3 << PYEOF
import json, subprocess, sys, re

sites = json.load(open('$SITES_FILE'))

for site in sites:
    name = site.get('name', site['url'])
    url = site['url']
    domain = re.sub(r'https?://', '', url).split('/')[0]

    # HTTP check
    try:
        result = subprocess.run(
            ['curl', '-o', '/dev/null', '-s', '-w', '%{http_code}|%{time_total}', '--max-time', '10', url],
            capture_output=True, text=True, timeout=15
        )
        parts = result.stdout.strip().split('|')
        http_code = parts[0] if parts else '000'
        resp_ms = int(float(parts[1]) * 1000) if len(parts) > 1 else 0
    except Exception:
        http_code = '000'
        resp_ms = 0

    # SSL check
    try:
        result = subprocess.run(
            ['openssl', 's_client', '-connect', f'{domain}:443', '-servername', domain],
            input='', capture_output=True, text=True, timeout=10
        )
        cert_result = subprocess.run(
            ['openssl', 'x509', '-noout', '-enddate'],
            input=result.stdout + result.stderr, capture_output=True, text=True
        )
        date_str = cert_result.stdout.strip().replace('notAfter=', '')
        from datetime import datetime
        expiry = datetime.strptime(date_str, '%b %d %H:%M:%S %Y %Z')
        ssl_days = (expiry - datetime.utcnow()).days
    except Exception:
        ssl_days = -1

    # Status
    code = int(http_code) if http_code.isdigit() else 0
    if code == 0 or code >= 500:
        status = "🔴"
    elif code >= 400:
        status = "⚠️ "
    else:
        status = "✅"

    # SSL indicator
    if ssl_days < 0:
        ssl_str = "N/A"
    elif ssl_days < 7:
        ssl_str = f"🔴 {ssl_days}d"
    elif ssl_days < 30:
        ssl_str = f"⚠️  {ssl_days}d"
    else:
        ssl_str = f"✅ {ssl_days}d"

    print(f"{name:<30} {status:<8} {http_code:<10} {resp_ms:<12} {ssl_str}")
PYEOF

echo ""
