#!/bin/bash
# gsc-export.sh — Export GSC data to CSV
# Usage: ./gsc-export.sh --site https://fuelvm.com/ --start 2026-01-01 --end 2026-01-31 --dimension query --output rankings.csv
# macOS bash 3.2 compatible

CREDS_DIR="$HOME/.openclaw/gsc-credentials"
TOKEN_FILE="$CREDS_DIR/token.json"

SITE=""
START_DATE=""
END_DATE=""
DIMENSION="query"
OUTPUT="gsc-export.csv"
ROW_LIMIT=25000

while [ $# -gt 0 ]; do
  case "$1" in
    --site)       SITE="$2";       shift 2 ;;
    --start)      START_DATE="$2"; shift 2 ;;
    --end)        END_DATE="$2";   shift 2 ;;
    --dimension)  DIMENSION="$2";  shift 2 ;;
    --output)     OUTPUT="$2";     shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [ -z "$SITE" ] || [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
  echo "Usage: $0 --site https://example.com/ --start YYYY-MM-DD --end YYYY-MM-DD [--dimension query|page|device|country] [--output file.csv]"
  exit 1
fi

if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ No credentials found. Run gsc-auth.sh first."
  exit 1
fi

echo "📊 Exporting GSC data for: $SITE"
echo "   Period: $START_DATE → $END_DATE"
echo "   Dimension: $DIMENSION"
echo "   Output: $OUTPUT"
echo ""

python3 << PYEOF
import json, urllib.request, urllib.error, sys, csv, os

TOKEN_FILE = "$TOKEN_FILE"
SITE = "$SITE"
START_DATE = "$START_DATE"
END_DATE = "$END_DATE"
DIMENSION = "$DIMENSION"
OUTPUT = "$OUTPUT"
ROW_LIMIT = $ROW_LIMIT
CREDS_DIR = "$CREDS_DIR"

def refresh_token(token_data):
    creds_file = os.path.join(CREDS_DIR, 'client_secret.json')
    if not os.path.exists(creds_file):
        print("❌ client_secret.json not found in", CREDS_DIR)
        sys.exit(1)
    with open(creds_file) as f:
        client = json.load(f).get('installed', json.load(open(creds_file)))

    payload = {
        'client_id': client['client_id'],
        'client_secret': client['client_secret'],
        'refresh_token': token_data['refresh_token'],
        'grant_type': 'refresh_token'
    }
    data = urllib.parse.urlencode(payload).encode()
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data, method='POST')
    with urllib.request.urlopen(req) as r:
        new_token = json.loads(r.read())
    token_data['access_token'] = new_token['access_token']
    with open(TOKEN_FILE, 'w') as f:
        json.dump(token_data, f)
    return token_data['access_token']

import urllib.parse

with open(TOKEN_FILE) as f:
    token_data = json.load(f)

access_token = token_data.get('access_token', '')

# Encode site URL for API path
encoded_site = urllib.parse.quote(SITE, safe='')
api_url = f"https://searchconsole.googleapis.com/webmasters/v3/sites/{encoded_site}/searchAnalytics/query"

all_rows = []
start_row = 0

print("Fetching", end='', flush=True)

while True:
    payload = {
        "startDate": START_DATE,
        "endDate": END_DATE,
        "dimensions": [DIMENSION],
        "rowLimit": ROW_LIMIT,
        "startRow": start_row
    }
    body = json.dumps(payload).encode()
    req = urllib.request.Request(api_url, data=body, method='POST', headers={
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    })

    try:
        with urllib.request.urlopen(req) as r:
            result = json.loads(r.read())
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print("\n🔄 Token expired, refreshing...")
            access_token = refresh_token(token_data)
            continue
        else:
            print(f"\n❌ API error {e.code}: {e.read().decode()}")
            sys.exit(1)

    rows = result.get('rows', [])
    if not rows:
        break

    all_rows.extend(rows)
    start_row += len(rows)
    print('.', end='', flush=True)

    if len(rows) < ROW_LIMIT:
        break

print(f"\n✅ Fetched {len(all_rows)} rows")

if not all_rows:
    print("⚠️  No data returned for this period/site.")
    sys.exit(0)

with open(OUTPUT, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([DIMENSION, 'clicks', 'impressions', 'ctr', 'position'])
    for row in all_rows:
        keys = row.get('keys', [''])
        writer.writerow([
            keys[0],
            row.get('clicks', 0),
            row.get('impressions', 0),
            round(row.get('ctr', 0) * 100, 2),
            round(row.get('position', 0), 1)
        ])

print(f"💾 Saved to: {OUTPUT}")
PYEOF
