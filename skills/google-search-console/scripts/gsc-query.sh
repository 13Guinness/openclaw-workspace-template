#!/usr/bin/env bash
# gsc-query.sh — Query Google Search Console Search Analytics API
# macOS bash 3.2 compatible | uses curl + python3
# Credentials read from: ~/.openclaw/gsc-credentials/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDS_DIR="${GSC_CREDENTIALS_DIR:-$HOME/.openclaw/gsc-credentials}"
TOKENS_FILE="$CREDS_DIR/tokens.json"
SA_FILE="$CREDS_DIR/service-account.json"
OAUTH_CLIENT_FILE="$CREDS_DIR/oauth-client.json"

GSC_API="https://www.googleapis.com/webmasters/v3"
MAX_RETRIES=3
RETRY_DELAY=2

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()    { printf "  %s\n" "$*"; }
ok()     { printf "✅ %s\n" "$*"; }
warn()   { printf "⚠️  %s\n" "$*" >&2; }
err()    { printf "❌ %s\n" "$*" >&2; exit 1; }
header() { printf "\n📊 %s\n%s\n" "$*" "──────────────────────────────────────────────────────────────────────"; }
dim()    { printf "   \033[2m%s\033[0m\n" "$*"; }

usage() {
  cat <<EOF

Usage: $(basename "$0") [OPTIONS]

Site Selection:
  --site URL          GSC property URL (e.g. "https://example.com/")
                      Use sc-domain:example.com for domain properties
  --list-sites        List all verified properties and exit

Date Range:
  --days N            Last N days (default: 28)
  --start-date DATE   Start date YYYY-MM-DD
  --end-date DATE     End date YYYY-MM-DD

Query Type:
  --type queries      Top keywords (default)
  --type pages        Top pages
  --type devices      Device breakdown
  --type countries    Country breakdown
  --type dates        Daily trend

Dimensions (for --type queries, can stack):
  --dimension query|page|device|country|date

Filters:
  --filter-query TEXT       Filter to rows matching this keyword
  --filter-page PATH        Filter to rows matching this page path
  --filter-device TYPE      mobile|desktop|tablet
  --filter-country CODE     ISO 3166-1 alpha-3 (e.g. usa, gbr, can)
  --filter-max-ctr N        Only show rows with CTR <= N (e.g. 0.03 for 3%)
  --filter-max-position N   Only show rows with avg position <= N

Output:
  --sort clicks|impressions|ctr|position (default: clicks)
  --limit N           Max rows to return (default: 25, max: 25000)
  --json              Output raw JSON instead of table
  --csv               Output CSV instead of table
  --no-header         Suppress table header (useful with --csv)

Auth:
  --method oauth|service-account  (auto-detected from available credentials)

Examples:
  # List verified sites
  bash gsc-query.sh --list-sites

  # Top keywords, last 28 days
  bash gsc-query.sh --site "https://example.com/"

  # Top pages sorted by impressions
  bash gsc-query.sh --site "https://example.com/" --type pages --sort impressions

  # Keywords for a specific page
  bash gsc-query.sh --site "https://example.com/" --filter-page "/blog/post/"

  # Pages ranking for a keyword
  bash gsc-query.sh --site "https://example.com/" --type pages --filter-query "seo tools"

  # Mobile traffic, last 90 days
  bash gsc-query.sh --site "https://example.com/" --filter-device mobile --days 90

  # Daily trend for specific keyword
  bash gsc-query.sh --site "https://example.com/" --type dates --filter-query "my keyword"

EOF
  exit 0
}

# ─── Argument Defaults ────────────────────────────────────────────────────────
SITE="${GSC_SITE:-}"
QUERY_TYPE="queries"
DAYS="${GSC_DAYS:-28}"
START_DATE=""
END_DATE=""
FILTER_QUERY=""
FILTER_PAGE=""
FILTER_DEVICE=""
FILTER_COUNTRY=""
FILTER_MAX_CTR=""
FILTER_MAX_POS=""
SORT_BY="clicks"
ROW_LIMIT=25
LIST_SITES=0
OUTPUT_FORMAT="table"
NO_HEADER=0
EXTRA_DIMENSIONS=""
METHOD="${GSC_AUTH_METHOD:-auto}"

# ─── Arg Parsing ─────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --site)             SITE="$2"; shift 2 ;;
    --list-sites)       LIST_SITES=1; shift ;;
    --type)             QUERY_TYPE="$2"; shift 2 ;;
    --days)             DAYS="$2"; shift 2 ;;
    --start-date)       START_DATE="$2"; shift 2 ;;
    --end-date)         END_DATE="$2"; shift 2 ;;
    --dimension)        EXTRA_DIMENSIONS="$EXTRA_DIMENSIONS $2"; shift 2 ;;
    --filter-query)     FILTER_QUERY="$2"; shift 2 ;;
    --filter-page)      FILTER_PAGE="$2"; shift 2 ;;
    --filter-device)    FILTER_DEVICE="$2"; shift 2 ;;
    --filter-country)   FILTER_COUNTRY="$2"; shift 2 ;;
    --filter-max-ctr)   FILTER_MAX_CTR="$2"; shift 2 ;;
    --filter-max-position) FILTER_MAX_POS="$2"; shift 2 ;;
    --sort)             SORT_BY="$2"; shift 2 ;;
    --limit)            ROW_LIMIT="$2"; shift 2 ;;
    --json)             OUTPUT_FORMAT="json"; shift ;;
    --csv)              OUTPUT_FORMAT="csv"; shift ;;
    --no-header)        NO_HEADER=1; shift ;;
    --method)           METHOD="$2"; shift 2 ;;
    --help|-h)          usage ;;
    *)                  err "Unknown argument: $1. Use --help for usage." ;;
  esac
done

# ─── Date calculation ─────────────────────────────────────────────────────────
compute_dates() {
  if [ -z "$START_DATE" ] && [ -z "$END_DATE" ]; then
    END_DATE=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d "3 days ago" +%Y-%m-%d)
    START_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS} days ago" +%Y-%m-%d)
  elif [ -z "$START_DATE" ]; then
    START_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS} days ago" +%Y-%m-%d)
  elif [ -z "$END_DATE" ]; then
    END_DATE=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d "3 days ago" +%Y-%m-%d)
  fi
}

# ─── Auth: get access token ───────────────────────────────────────────────────
get_token() {
  # Auto-detect method if not specified
  if [ "$METHOD" = "auto" ]; then
    if [ -f "$TOKENS_FILE" ]; then
      METHOD="oauth"
    elif [ -f "$SA_FILE" ]; then
      METHOD="service-account"
    else
      err "No credentials found. Run: bash gsc-auth.sh"
    fi
  fi

  if [ "$METHOD" = "oauth" ]; then
    _refresh_oauth_token
  else
    _get_sa_token
  fi
}

_refresh_oauth_token() {
  python3 - <<'PYEOF'
import json, sys, time, urllib.request, urllib.parse, os

creds_dir = os.environ.get("GSC_CREDENTIALS_DIR", os.path.expanduser("~/.openclaw/gsc-credentials"))
tokens_file = os.path.join(creds_dir, "tokens.json")
client_file = os.path.join(creds_dir, "oauth-client.json")

if not os.path.exists(tokens_file):
    print("ERROR: No tokens found. Run: bash gsc-auth.sh --method oauth", file=sys.stderr)
    sys.exit(1)

with open(tokens_file) as f:
    tokens = json.load(f)

expiry = tokens.get("token_expiry", 0)
if expiry and time.time() < expiry - 60:
    print(tokens["access_token"])
    sys.exit(0)

with open(client_file) as f:
    raw = json.load(f)
    k = list(raw.keys())[0]
    client_id = raw[k]["client_id"]
    client_secret = raw[k]["client_secret"]

data = urllib.parse.urlencode({
    "grant_type": "refresh_token",
    "refresh_token": tokens["refresh_token"],
    "client_id": client_id,
    "client_secret": client_secret,
}).encode()

req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data)
try:
    resp = urllib.request.urlopen(req)
    new_tokens = json.loads(resp.read())
except Exception as e:
    print(f"ERROR: Token refresh failed: {e}", file=sys.stderr)
    sys.exit(1)

tokens["access_token"] = new_tokens["access_token"]
tokens["token_expiry"] = time.time() + new_tokens.get("expires_in", 3600)
with open(tokens_file, "w") as f:
    json.dump(tokens, f, indent=2)
os.chmod(tokens_file, 0o600)
print(new_tokens["access_token"])
PYEOF
}

_get_sa_token() {
  python3 - <<'PYEOF'
import json, sys, time, base64, urllib.request, urllib.parse, os, subprocess, tempfile

creds_dir = os.environ.get("GSC_CREDENTIALS_DIR", os.path.expanduser("~/.openclaw/gsc-credentials"))
sa_file = os.path.join(creds_dir, "service-account.json")

if not os.path.exists(sa_file):
    print("ERROR: No service account file found. Run: bash gsc-auth.sh --method service-account", file=sys.stderr)
    sys.exit(1)

with open(sa_file) as f:
    sa = json.load(f)

def b64url(data):
    if isinstance(data, str): data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

now = int(time.time())
header = {"alg": "RS256", "typ": "JWT"}
payload = {
    "iss": sa["client_email"],
    "scope": "https://www.googleapis.com/auth/webmasters.readonly",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now, "exp": now + 3600,
}
h = b64url(json.dumps(header, separators=(",",":"))); p = b64url(json.dumps(payload, separators=(",",":")))
signing_input = f"{h}.{p}"

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding
    key = serialization.load_pem_private_key(sa["private_key"].encode(), password=None)
    sig = key.sign(signing_input.encode(), padding.PKCS1v15(), hashes.SHA256())
except ImportError:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False) as kf:
        kf.write(sa["private_key"]); key_path = kf.name
    try:
        r = subprocess.run(["openssl","dgst","-sha256","-sign",key_path], input=signing_input.encode(), capture_output=True)
        if r.returncode != 0:
            print("ERROR: JWT signing failed. Install cryptography: pip3 install cryptography", file=sys.stderr); sys.exit(1)
        sig = r.stdout
    finally:
        os.unlink(key_path)

jwt = f"{signing_input}.{b64url(sig)}"
data = urllib.parse.urlencode({"grant_type":"urn:ietf:params:oauth:grant-type:jwt-bearer","assertion":jwt}).encode()
req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data)
resp = urllib.request.urlopen(req)
print(json.loads(resp.read())["access_token"])
PYEOF
}

# ─── API call with retry ──────────────────────────────────────────────────────
api_call() {
  local url="$1"
  local data="${2:-}"
  local token="$3"
  local attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    if [ -n "$data" ]; then
      RESPONSE=$(curl -sf -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$url" 2>&1) && break
    else
      RESPONSE=$(curl -sf \
        -H "Authorization: Bearer $token" \
        "$url" 2>&1) && break
    fi

    if [ $attempt -lt $MAX_RETRIES ]; then
      warn "API call failed (attempt $attempt/$MAX_RETRIES). Retrying in ${RETRY_DELAY}s..."
      sleep $RETRY_DELAY
      RETRY_DELAY=$((RETRY_DELAY * 2))
    else
      # Try to extract error message
      ERROR_MSG=$(echo "$RESPONSE" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    e=d.get('error',{})
    print(f\"{e.get('code','?')} {e.get('message','Unknown error')}\")
except:
    print('Unknown API error')
" 2>/dev/null || echo "API request failed")
      err "API call failed after $MAX_RETRIES attempts: $ERROR_MSG"
    fi
    attempt=$((attempt + 1))
  done

  echo "$RESPONSE"
}

# ─── List sites ───────────────────────────────────────────────────────────────
list_sites() {
  log "Fetching verified GSC properties..."
  TOKEN=$(get_token) || exit 1

  RESPONSE=$(api_call "${GSC_API}/sites" "" "$TOKEN")

  echo ""
  printf "🌐 Verified GSC Properties\n"
  printf "%s\n" "─────────────────────────────────────────"
  echo "$RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
entries = d.get('siteEntry', [])
if not entries:
    print('  (no verified properties found)')
    print()
    print('  Add sites at: https://search.google.com/search-console')
    sys.exit(0)
for s in sorted(entries, key=lambda x: x['siteUrl']):
    perm = s.get('permissionLevel', 'unknown')
    icon = '👑' if perm == 'siteOwner' else '👤'
    print(f\"  {icon} {s['siteUrl']:50} [{perm}]\")
print()
print(f'  Total: {len(entries)} propert{\"y\" if len(entries)==1 else \"ies\"}')
" 2>/dev/null || err "Could not parse sites response"
  echo ""
}

# ─── Build API request body ───────────────────────────────────────────────────
build_request() {
  local dimensions="$1"
  local start="$2"
  local end="$3"
  local limit="$4"
  local start_row="${5:-0}"

  python3 - <<PYEOF
import json, sys

dimensions_str = "$dimensions"
dimensions = [d.strip() for d in dimensions_str.split(",") if d.strip()]

body = {
    "startDate": "$start",
    "endDate": "$end",
    "dimensions": dimensions,
    "rowLimit": $limit,
    "startRow": $start_row,
}

filters = []
filter_query = """$FILTER_QUERY"""
filter_page = """$FILTER_PAGE"""
filter_device = """$FILTER_DEVICE"""
filter_country = """$FILTER_COUNTRY"""

if filter_query:
    filters.append({
        "dimension": "query",
        "operator": "contains",
        "expression": filter_query,
    })
if filter_page:
    filters.append({
        "dimension": "page",
        "operator": "contains",
        "expression": filter_page,
    })
if filter_device:
    filters.append({
        "dimension": "device",
        "operator": "equals",
        "expression": filter_device.lower(),
    })
if filter_country:
    filters.append({
        "dimension": "country",
        "operator": "equals",
        "expression": filter_country.lower(),
    })

if filters:
    body["dimensionFilterGroups"] = [{"filters": filters}]

print(json.dumps(body))
PYEOF
}

# ─── Determine dimensions for query type ─────────────────────────────────────
get_dimensions_for_type() {
  case "$QUERY_TYPE" in
    queries)   echo "query" ;;
    pages)     echo "page" ;;
    devices)   echo "device" ;;
    countries) echo "country" ;;
    dates)     echo "date" ;;
    *)         err "Unknown type: $QUERY_TYPE. Use: queries, pages, devices, countries, dates" ;;
  esac
}

# ─── Format and display results ───────────────────────────────────────────────
format_results() {
  local raw_json="$1"
  local primary_dim="$2"
  local start="$3"
  local end="$4"

  if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "$raw_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin), indent=2))"
    return
  fi

  python3 - <<PYEOF
import json, sys, os

raw = json.loads("""$(echo "$raw_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")""")
rows = raw.get("rows", [])

dim = "$primary_dim"
site = "$SITE"
start = "$start"
end = "$end"
sort_by = "$SORT_BY"
fmt = "$OUTPUT_FORMAT"
no_header = "$NO_HEADER" == "1"
max_ctr = float("$FILTER_MAX_CTR") if "$FILTER_MAX_CTR" else None
max_pos = float("$FILTER_MAX_POS") if "$FILTER_MAX_POS" else None

# Apply post-filters
if max_ctr is not None:
    rows = [r for r in rows if r.get("ctr", 1) <= max_ctr]
if max_pos is not None:
    rows = [r for r in rows if r.get("position", 999) <= max_pos]

# Sort
sort_key = {"clicks": "clicks", "impressions": "impressions", "ctr": "ctr", "position": "position"}.get(sort_by, "clicks")
reverse = sort_key != "position"
rows.sort(key=lambda r: r.get(sort_key, 0), reverse=reverse)

if fmt == "csv":
    import csv, io
    out = io.StringIO()
    writer = csv.writer(out)
    if not no_header:
        writer.writerow(["dimension", "clicks", "impressions", "ctr", "position"])
    for row in rows:
        keys = row.get("keys", ["(unknown)"])
        val = " | ".join(keys)
        writer.writerow([
            val,
            row.get("clicks", 0),
            row.get("impressions", 0),
            f'{row.get("ctr", 0):.4f}',
            f'{row.get("position", 0):.1f}',
        ])
    print(out.getvalue(), end="")
    return

# Table output
if not no_header:
    type_labels = {
        "query": "Keywords", "page": "Pages", "device": "Devices",
        "country": "Countries", "date": "Dates"
    }
    print(f"\n📊 GSC {type_labels.get(dim, dim)} — {site}")
    print(f"   {start} to {end} | {len(rows)} row{'s' if len(rows) != 1 else ''}")
    if max_ctr or max_pos:
        filters = []
        if max_ctr: filters.append(f"CTR ≤ {max_ctr*100:.1f}%")
        if max_pos: filters.append(f"position ≤ {max_pos}")
        print(f"   Filters: {', '.join(filters)}")
    print("──────────────────────────────────────────────────────────────────────")

col_w = 42 if dim in ("query", "page") else 20
header_fmt = f"{{:<{col_w}}}  {{:>7}}  {{:>8}}  {{:>6}}  {{:>8}}"
row_fmt    = f"{{:<{col_w}}}  {{:>7,}}  {{:>8,}}  {{:>6}}  {{:>8}}"

if not no_header:
    label = {"query": "Keyword", "page": "Page", "device": "Device",
             "country": "Country", "date": "Date"}.get(dim, "Value")
    print(header_fmt.format(label, "Clicks", "Impr", "CTR", "Position"))
    print("──────────────────────────────────────────────────────────────────────")

total_clicks = 0
total_impr = 0

for row in rows:
    keys = row.get("keys", ["(unknown)"])
    val = " | ".join(keys)
    clicks = int(row.get("clicks", 0))
    impr = int(row.get("impressions", 0))
    ctr = row.get("ctr", 0)
    pos = row.get("position", 0)

    total_clicks += clicks
    total_impr += impr

    # Truncate long values
    if len(val) > col_w:
        val = val[:col_w-1] + "…"

    print(row_fmt.format(val, clicks, impr, f"{ctr*100:.2f}%", f"{pos:.1f}"))

if not no_header and rows:
    print("──────────────────────────────────────────────────────────────────────")
    avg_ctr = total_clicks / total_impr if total_impr else 0
    print(f"{'TOTAL':<{col_w}}  {total_clicks:>7,}  {total_impr:>8,}  {avg_ctr*100:>5.2f}%  {'—':>8}")

if not rows:
    print(f"  (no data found for this query)")
    print(f"  Try: --days 90, or check --list-sites for correct property URL")
print()
PYEOF
}

# ─── Main query execution ─────────────────────────────────────────────────────
run_query() {
  [ -z "$SITE" ] && err "No site specified. Use --site URL or set GSC_SITE environment variable."

  compute_dates
  TOKEN=$(get_token) || exit 1

  DIM=$(get_dimensions_for_type)
  ENCODED_SITE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SITE', safe=''))")

  URL="${GSC_API}/sites/${ENCODED_SITE}/searchAnalytics/query"
  REQUEST_BODY=$(build_request "$DIM" "$START_DATE" "$END_DATE" "$ROW_LIMIT" "0")

  if [ "$OUTPUT_FORMAT" = "table" ]; then
    log "Querying GSC for $QUERY_TYPE ($START_DATE → $END_DATE)..."
  fi

  RESPONSE=$(api_call "$URL" "$REQUEST_BODY" "$TOKEN")

  # Check for API errors in response body
  python3 -c "
import json, sys
d = json.loads('''$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")''')
if 'error' in d:
    e = d['error']
    print(f\"ERROR: {e.get('code','?')} {e.get('message','Unknown')}\", file=sys.stderr)
    sys.exit(1)
" 2>&1 | grep -q "ERROR" && err "$(echo "$RESPONSE" | python3 -c "import json,sys; e=json.load(sys.stdin).get('error',{}); print(f\"{e.get('code','?')} {e.get('message','Unknown')}\")" 2>/dev/null || echo "API error")"

  format_results "$RESPONSE" "$DIM" "$START_DATE" "$END_DATE"
}

# ─── Main dispatch ─────────────────────────────────────────────────────────────
if [ "$LIST_SITES" = "1" ]; then
  list_sites
else
  run_query
fi
