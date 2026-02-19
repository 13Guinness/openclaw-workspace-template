#!/bin/bash
# add-site.sh — Add a site to the monitoring list
# Usage: ./add-site.sh --name "FuelVM" --url "https://fuelvm.com"
# macOS bash 3.2 compatible

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITES_FILE="$SCRIPT_DIR/../config/sites.json"

NAME=""
URL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --url)  URL="$2";  shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [ -z "$NAME" ] || [ -z "$URL" ]; then
  echo "Usage: $0 --name 'Site Name' --url 'https://example.com'"
  exit 1
fi

# Init file if missing
if [ ! -f "$SITES_FILE" ]; then
  echo "[]" > "$SITES_FILE"
fi

# Check for duplicate
EXISTING=$(python3 -c "
import json
data = json.load(open('$SITES_FILE'))
print(any(s['url'] == '$URL' for s in data))
")

if [ "$EXISTING" = "True" ]; then
  echo "⚠️  $URL is already in the list."
  exit 0
fi

# Append site
python3 -c "
import json
data = json.load(open('$SITES_FILE'))
data.append({'name': '$NAME', 'url': '$URL'})
with open('$SITES_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print('✅ Added: $NAME ($URL)')
"

# Quick curl test
echo "Testing connectivity..."
HTTP=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$URL")
if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 400 ]; then
  echo "✅ Site is reachable (HTTP $HTTP)"
else
  echo "⚠️  Site returned HTTP $HTTP — double check the URL"
fi
