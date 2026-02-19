#!/usr/bin/env bash
# gsc-auth.sh — Google Search Console OAuth2 / Service Account setup
# macOS bash 3.2 compatible | uses curl + python3
# Credentials stored in: ~/.openclaw/gsc-credentials/

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
CREDS_DIR="${GSC_CREDENTIALS_DIR:-$HOME/.openclaw/gsc-credentials}"
OAUTH_CLIENT_FILE="$CREDS_DIR/oauth-client.json"
TOKENS_FILE="$CREDS_DIR/tokens.json"
SA_FILE="$CREDS_DIR/service-account.json"

SCOPE="https://www.googleapis.com/auth/webmasters.readonly"
TOKEN_URL="https://oauth2.googleapis.com/token"
AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth"
REDIRECT_URI="urn:ietf:wg:oauth:2.0:oob"   # manual copy-paste flow

# ─── Helpers ─────────────────────────────────────────────────────────────────
log()     { printf "  %s\n" "$*"; }
ok()      { printf "✅ %s\n" "$*"; }
warn()    { printf "⚠️  %s\n" "$*" >&2; }
err()     { printf "❌ %s\n" "$*" >&2; exit 1; }
header()  { printf "\n🔑 %s\n%s\n" "$*" "────────────────────────────────────────"; }

usage() {
  cat <<EOF

Usage: $(basename "$0") [OPTIONS]

  --method oauth            Authenticate with a personal Google account (default)
  --method service-account  Authenticate with a service account JSON key
  --test                    Test current credentials without re-authenticating
  --force                   Force re-authentication even if tokens exist
  --status                  Show current credential status
  --help                    Show this help

Examples:
  bash gsc-auth.sh                         # OAuth2 setup (interactive)
  bash gsc-auth.sh --method service-account
  bash gsc-auth.sh --test
  bash gsc-auth.sh --method oauth --force  # Re-authenticate

EOF
  exit 0
}

# ─── Arg parsing ─────────────────────────────────────────────────────────────
METHOD="${GSC_AUTH_METHOD:-oauth}"
FORCE=0
TEST_ONLY=0
STATUS_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --method)         METHOD="$2"; shift 2 ;;
    --force)          FORCE=1; shift ;;
    --test)           TEST_ONLY=1; shift ;;
    --status)         STATUS_ONLY=1; shift ;;
    --help|-h)        usage ;;
    *)                err "Unknown argument: $1. Use --help for usage." ;;
  esac
done

# ─── Directory setup ─────────────────────────────────────────────────────────
mkdir -p "$CREDS_DIR"
chmod 700 "$CREDS_DIR"

# ─── Credential status display ───────────────────────────────────────────────
show_status() {
  header "GSC Credential Status"

  if [ -f "$OAUTH_CLIENT_FILE" ]; then
    CLIENT_ID=$(python3 -c "import json,sys; d=json.load(open('$OAUTH_CLIENT_FILE')); k=list(d.keys())[0]; print(d[k].get('client_id','?')[:20]+'...')" 2>/dev/null || echo "unreadable")
    ok "OAuth client file found (ID: $CLIENT_ID)"
  else
    warn "No OAuth client file at: $OAUTH_CLIENT_FILE"
  fi

  if [ -f "$TOKENS_FILE" ]; then
    HAS_REFRESH=$(python3 -c "import json; d=json.load(open('$TOKENS_FILE')); print('yes' if d.get('refresh_token') else 'no')" 2>/dev/null || echo "no")
    EXPIRY=$(python3 -c "import json; d=json.load(open('$TOKENS_FILE')); print(d.get('token_expiry','unknown'))" 2>/dev/null || echo "unknown")
    if [ "$HAS_REFRESH" = "yes" ]; then
      ok "OAuth tokens file found (refresh token present, expires: $EXPIRY)"
    else
      warn "OAuth tokens file found but no refresh token"
    fi
  else
    warn "No tokens file — run: bash gsc-auth.sh --method oauth"
  fi

  if [ -f "$SA_FILE" ]; then
    SA_EMAIL=$(python3 -c "import json; print(json.load(open('$SA_FILE')).get('client_email','?'))" 2>/dev/null || echo "unreadable")
    ok "Service account file found ($SA_EMAIL)"
  else
    warn "No service account file at: $SA_FILE"
  fi

  echo ""
}

if [ "$STATUS_ONLY" = "1" ]; then
  show_status
  exit 0
fi

# ─── Utility: get a fresh access token ───────────────────────────────────────
# Called by other scripts via: source gsc-auth.sh && get_access_token
get_access_token() {
  if [ "$METHOD" = "service-account" ] || [ -f "$SA_FILE" -a ! -f "$TOKENS_FILE" ]; then
    _get_sa_token
  else
    _get_oauth_token
  fi
}

# OAuth2: refresh access token from stored refresh token
_get_oauth_token() {
  if [ ! -f "$TOKENS_FILE" ]; then
    err "No tokens found. Run: bash gsc-auth.sh --method oauth"
  fi
  if [ ! -f "$OAUTH_CLIENT_FILE" ]; then
    err "No OAuth client file found at: $OAUTH_CLIENT_FILE"
  fi

  python3 - <<'PYEOF'
import json, sys, urllib.request, urllib.parse, time, os

creds_dir = os.environ.get("GSC_CREDENTIALS_DIR", os.path.expanduser("~/.openclaw/gsc-credentials"))
tokens_file = os.path.join(creds_dir, "tokens.json")
client_file = os.path.join(creds_dir, "oauth-client.json")

with open(tokens_file) as f:
    tokens = json.load(f)
with open(client_file) as f:
    raw = json.load(f)
    app_key = list(raw.keys())[0]
    client_id = raw[app_key]["client_id"]
    client_secret = raw[app_key]["client_secret"]

# Check if current token is still valid (with 60s buffer)
expiry = tokens.get("token_expiry", 0)
if expiry and time.time() < expiry - 60:
    print(tokens["access_token"])
    sys.exit(0)

# Refresh the token
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

# Service account: create JWT and get access token
_get_sa_token() {
  if [ ! -f "$SA_FILE" ]; then
    err "No service account file found at: $SA_FILE"
  fi

  python3 - <<'PYEOF'
import json, sys, time, base64, hashlib, urllib.request, urllib.parse, os

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding
    HAS_CRYPTO = True
except ImportError:
    HAS_CRYPTO = False

creds_dir = os.environ.get("GSC_CREDENTIALS_DIR", os.path.expanduser("~/.openclaw/gsc-credentials"))
sa_file = os.path.join(creds_dir, "service-account.json")

with open(sa_file) as f:
    sa = json.load(f)

def b64url(data):
    if isinstance(data, str):
        data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

now = int(time.time())
header = {"alg": "RS256", "typ": "JWT"}
payload = {
    "iss": sa["client_email"],
    "scope": "https://www.googleapis.com/auth/webmasters.readonly",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now,
    "exp": now + 3600,
}

header_enc = b64url(json.dumps(header, separators=(",", ":")))
payload_enc = b64url(json.dumps(payload, separators=(",", ":")))
signing_input = f"{header_enc}.{payload_enc}"

if HAS_CRYPTO:
    private_key = serialization.load_pem_private_key(
        sa["private_key"].encode(), password=None
    )
    signature = private_key.sign(signing_input.encode(), padding.PKCS1v15(), hashes.SHA256())
else:
    # Fallback: use openssl via subprocess
    import subprocess, tempfile
    key_pem = sa["private_key"]
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False) as kf:
        kf.write(key_pem)
        key_path = kf.name
    try:
        result = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_path],
            input=signing_input.encode(),
            capture_output=True,
        )
        if result.returncode != 0:
            print("ERROR: openssl signing failed. Install 'cryptography' package: pip3 install cryptography", file=sys.stderr)
            sys.exit(1)
        signature = result.stdout
    finally:
        os.unlink(key_path)

jwt = f"{signing_input}.{b64url(signature)}"

data = urllib.parse.urlencode({
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion": jwt,
}).encode()

req = urllib.request.Request("https://oauth2.googleapis.com/token", data=data)
try:
    resp = urllib.request.urlopen(req)
    result = json.loads(resp.read())
    print(result["access_token"])
except Exception as e:
    print(f"ERROR: Failed to get service account token: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

# ─── Test existing credentials ────────────────────────────────────────────────
test_credentials() {
  header "Testing GSC Credentials"
  log "Fetching access token..."

  TOKEN=$(_get_oauth_token 2>/dev/null || _get_sa_token 2>/dev/null || echo "")
  if [ -z "$TOKEN" ]; then
    err "Could not get a valid access token. Run: bash gsc-auth.sh"
  fi

  log "Testing API access (listing sites)..."
  RESPONSE=$(curl -sf \
    -H "Authorization: Bearer $TOKEN" \
    "https://www.googleapis.com/webmasters/v3/sites" 2>&1) || true

  if echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('siteEntry',[])), 'site(s) accessible')" 2>/dev/null; then
    ok "Authentication working!"
    log ""
    log "Accessible properties:"
    echo "$RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for s in d.get('siteEntry', []):
    print(f\"  {s.get('permissionLevel','?'):12} {s['siteUrl']}\")" 2>/dev/null || true
  else
    HTTP_ERR=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error',{}).get('message','unknown'))" 2>/dev/null || echo "unknown")
    err "API call failed: $HTTP_ERR"
  fi
  echo ""
}

if [ "$TEST_ONLY" = "1" ]; then
  test_credentials
  exit 0
fi

# ─── OAuth2 Setup ─────────────────────────────────────────────────────────────
setup_oauth() {
  header "OAuth2 Setup — Personal Google Account"

  # Check for existing valid tokens
  if [ "$FORCE" = "0" ] && [ -f "$TOKENS_FILE" ]; then
    HAS_REFRESH=$(python3 -c "import json; d=json.load(open('$TOKENS_FILE')); print('yes' if d.get('refresh_token') else 'no')" 2>/dev/null || echo "no")
    if [ "$HAS_REFRESH" = "yes" ]; then
      ok "Valid tokens already found. Use --force to re-authenticate."
      test_credentials
      exit 0
    fi
  fi

  # Verify OAuth client file exists
  if [ ! -f "$OAUTH_CLIENT_FILE" ]; then
    cat <<EOF
⚠️  No OAuth client file found.

You need to create OAuth2 credentials in Google Cloud Console first:

  1. Go to: https://console.cloud.google.com/
  2. Select or create a project
  3. Enable: APIs & Services → Library → "Google Search Console API"
  4. Create credentials: APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID
  5. Application type: Desktop app
  6. Download the JSON file
  7. Save it to: $OAUTH_CLIENT_FILE

Also configure the OAuth consent screen:
  APIs & Services → OAuth consent screen → External → Add your email as test user

EOF
    read -r -p "Press Enter when the file is in place, or Ctrl+C to cancel: "
    echo ""
  fi

  if [ ! -f "$OAUTH_CLIENT_FILE" ]; then
    err "OAuth client file still not found at: $OAUTH_CLIENT_FILE"
  fi

  # Read client credentials
  CLIENT_ID=$(python3 -c "
import json; raw=json.load(open('$OAUTH_CLIENT_FILE'))
k=list(raw.keys())[0]; print(raw[k]['client_id'])" 2>/dev/null) || err "Could not read client_id from $OAUTH_CLIENT_FILE"

  CLIENT_SECRET=$(python3 -c "
import json; raw=json.load(open('$OAUTH_CLIENT_FILE'))
k=list(raw.keys())[0]; print(raw[k]['client_secret'])" 2>/dev/null) || err "Could not read client_secret from $OAUTH_CLIENT_FILE"

  log "OAuth client loaded (ID: ${CLIENT_ID:0:20}...)"
  log ""

  # Build authorization URL
  AUTH_PARAMS="client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=${SCOPE}&access_type=offline&prompt=consent"
  FULL_AUTH_URL="${AUTH_URL}?${AUTH_PARAMS}"

  log "Opening authorization URL in your browser..."
  log "(If it doesn't open, copy the URL below and paste it in your browser)"
  echo ""
  echo "  $FULL_AUTH_URL"
  echo ""

  # Try to open browser
  open "$FULL_AUTH_URL" 2>/dev/null || true

  log "After authorizing, Google will show you a code. Paste it here:"
  echo ""
  read -r -p "  Authorization code: " AUTH_CODE
  echo ""

  if [ -z "$AUTH_CODE" ]; then
    err "No authorization code provided."
  fi

  log "Exchanging authorization code for tokens..."

  TOKEN_RESPONSE=$(curl -sf -X POST "$TOKEN_URL" \
    -d "code=$AUTH_CODE" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "redirect_uri=$REDIRECT_URI" \
    -d "grant_type=authorization_code" 2>&1) || err "Token exchange request failed"

  python3 - <<PYEOF
import json, sys, time, os

response = json.loads("""$TOKEN_RESPONSE""")

if "error" in response:
    print(f"❌ Token exchange failed: {response.get('error_description', response['error'])}", file=sys.stderr)
    sys.exit(1)

if "refresh_token" not in response:
    print("❌ No refresh token received. Try re-running with --force", file=sys.stderr)
    sys.exit(1)

tokens = {
    "access_token": response["access_token"],
    "refresh_token": response["refresh_token"],
    "token_expiry": time.time() + response.get("expires_in", 3600),
    "token_type": response.get("token_type", "Bearer"),
    "scope": response.get("scope", ""),
}

tokens_file = os.path.join(
    os.environ.get("GSC_CREDENTIALS_DIR", os.path.expanduser("~/.openclaw/gsc-credentials")),
    "tokens.json"
)
with open(tokens_file, "w") as f:
    json.dump(tokens, f, indent=2)
os.chmod(tokens_file, 0o600)
print("✅ Tokens saved successfully!")
PYEOF

  echo ""
  test_credentials
}

# ─── Service Account Setup ───────────────────────────────────────────────────
setup_service_account() {
  header "Service Account Setup"

  if [ ! -f "$SA_FILE" ]; then
    cat <<EOF
⚠️  No service account key found.

To set up a service account:

  1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
  2. Create a new service account (or select existing)
  3. Enable: APIs & Services → Library → "Google Search Console API"
  4. Create a JSON key: Actions → Manage Keys → Add Key → Create new key → JSON
  5. Save the downloaded file to: $SA_FILE

Then grant GSC access to the service account:
  6. Open: https://search.google.com/search-console
  7. Select your property → Settings → Users and permissions
  8. Add the service account email as a user (at least Restricted)
     (The email is in the JSON file under "client_email")

EOF
    read -r -p "Press Enter when the file is in place, or Ctrl+C to cancel: "
    echo ""
  fi

  if [ ! -f "$SA_FILE" ]; then
    err "Service account file still not found at: $SA_FILE"
  fi

  # Validate JSON structure
  python3 - <<PYEOF
import json, sys, os

sa_file = "$SA_FILE"
try:
    with open(sa_file) as f:
        sa = json.load(f)
except Exception as e:
    print(f"❌ Cannot read service account file: {e}", file=sys.stderr)
    sys.exit(1)

required = ["type", "project_id", "private_key_id", "private_key", "client_email"]
missing = [k for k in required if k not in sa]
if missing:
    print(f"❌ Service account JSON missing fields: {missing}", file=sys.stderr)
    sys.exit(1)

if sa.get("type") != "service_account":
    print(f"❌ JSON type is '{sa.get('type')}', expected 'service_account'", file=sys.stderr)
    sys.exit(1)

os.chmod(sa_file, 0o600)
print(f"✅ Service account file valid")
print(f"   Project: {sa['project_id']}")
print(f"   Email:   {sa['client_email']}")
PYEOF

  echo ""
  log "Testing service account API access..."
  export METHOD="service-account"
  test_credentials
}

# ─── Main dispatch ────────────────────────────────────────────────────────────
case "$METHOD" in
  oauth)           setup_oauth ;;
  service-account) setup_service_account ;;
  *)               err "Unknown method: $METHOD. Use 'oauth' or 'service-account'." ;;
esac
