#!/usr/bin/env bash
# =============================================================================
# generate-report.sh — Build monthly SEO HTML report from data/report-data.json
# =============================================================================
# Usage:
#   bash scripts/generate-report.sh [--data path/to/data.json]
#
# Environment variables (all optional — fall back to values in data JSON):
#   CLIENT_NAME      Client display name
#   CLIENT_DOMAIN    Client domain (e.g. acmecorp.com)
#   REPORT_MONTH     Full month name (e.g. "February")
#   REPORT_YEAR      Four-digit year (e.g. "2026")
#   BRAND_COLOR      Primary hex color (e.g. "#1a3c5e")
#   ACCENT_COLOR     Accent hex color  (e.g. "#e85d26")
#   LOGO_PATH        Path to logo PNG/SVG (embedded as base64)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE="${SKILL_DIR}/templates/report.html"
DATA_FILE="${SKILL_DIR}/data/report-data.json"
WORKSPACE_ROOT="${SKILL_DIR}/../../.."   # workspace/
REPORTS_BASE="${SKILL_DIR}/../../../reports"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --data)  DATA_FILE="$2"; shift 2 ;;
    --help)
      echo "Usage: bash generate-report.sh [--data path/to/report-data.json]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
for cmd in jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required. Install it and retry."
    echo "  macOS: brew install $cmd"
    exit 1
  fi
done

if [[ ! -f "$DATA_FILE" ]]; then
  echo "ERROR: Data file not found: $DATA_FILE"
  echo "  Create it from the template in SKILL.md > Section 2."
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template not found: $TEMPLATE"
  exit 1
fi

# ---------------------------------------------------------------------------
# Read JSON data
# ---------------------------------------------------------------------------
echo "Reading data from: $DATA_FILE"

jq_get() { jq -r "$1 // empty" "$DATA_FILE"; }

CLIENT_NAME="${CLIENT_NAME:-$(jq_get '.client.name')}"
CLIENT_DOMAIN="${CLIENT_DOMAIN:-$(jq_get '.client.domain')}"
REPORT_MONTH="${REPORT_MONTH:-$(jq_get '.period.month')}"
REPORT_YEAR="${REPORT_YEAR:-$(jq_get '.period.year')}"
PREV_MONTH="$(jq_get '.period.prev_month')"
BRAND_COLOR="${BRAND_COLOR:-$(jq_get '.brand.primary // "#1a3c5e"')}"
ACCENT_COLOR="${ACCENT_COLOR:-$(jq_get '.brand.accent // "#e85d26"')}"

# Sanitise client name for filename (lowercase, spaces→dashes, strip special chars)
CLIENT_SLUG="$(echo "$CLIENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')"
MONTH_NUM="$(python3 -c "import datetime; print(datetime.datetime.strptime('$REPORT_MONTH', '%B').strftime('%m'))" 2>/dev/null || echo "01")"
PERIOD_DIR="${REPORT_YEAR}-${MONTH_NUM}"

# ---------------------------------------------------------------------------
# Output directory
# ---------------------------------------------------------------------------
OUT_DIR="${REPORTS_BASE}/${PERIOD_DIR}"
mkdir -p "$OUT_DIR"

OUT_HTML="${OUT_DIR}/${CLIENT_SLUG}-seo-report-${PERIOD_DIR}.html"

echo "Client   : $CLIENT_NAME ($CLIENT_DOMAIN)"
echo "Period   : $REPORT_MONTH $REPORT_YEAR"
echo "Output   : $OUT_HTML"

# ---------------------------------------------------------------------------
# Logo — embed as base64 data URI if a path is provided
# ---------------------------------------------------------------------------
LOGO_DATA_URI=""
if [[ -n "${LOGO_PATH:-}" && -f "$LOGO_PATH" ]]; then
  MIME="image/png"
  [[ "$LOGO_PATH" == *.svg ]] && MIME="image/svg+xml"
  [[ "$LOGO_PATH" == *.jpg || "$LOGO_PATH" == *.jpeg ]] && MIME="image/jpeg"
  B64="$(base64 < "$LOGO_PATH" | tr -d '\n')"
  LOGO_DATA_URI="data:${MIME};base64,${B64}"
fi

# ---------------------------------------------------------------------------
# GSC metrics
# ---------------------------------------------------------------------------
CLICKS="$(jq_get '.gsc.clicks.value')"
CLICKS_DELTA="$(jq_get '.gsc.clicks.delta')"
IMPRESSIONS="$(jq_get '.gsc.impressions.value')"
IMPRESSIONS_DELTA="$(jq_get '.gsc.impressions.delta')"
CTR="$(jq_get '.gsc.ctr.value')"
CTR_DELTA="$(jq_get '.gsc.ctr.delta')"
AVG_POS="$(jq_get '.gsc.avg_position.value')"
AVG_POS_DELTA="$(jq_get '.gsc.avg_position.delta')"

# Format large numbers with commas
fmt_num() { python3 -c "print('{:,}'.format(int(float('$1'))))" 2>/dev/null || echo "$1"; }
fmt_delta() {
  local val="$1" symbol sign css_class
  val_f="$(python3 -c "print(float('$val'))" 2>/dev/null || echo "0")"
  if python3 -c "exit(0 if float('$val') > 0 else 1)" 2>/dev/null; then
    echo '<span class="delta positive">&#9650; '"$val"'%</span>'
  elif python3 -c "exit(0 if float('$val') < 0 else 1)" 2>/dev/null; then
    echo '<span class="delta negative">&#9660; '"${val#-}"'%</span>'
  else
    echo '<span class="delta neutral">&#9644; '"$val"'%</span>'
  fi
}

CLICKS_FMT="$(fmt_num "$CLICKS")"
IMPRESSIONS_FMT="$(fmt_num "$IMPRESSIONS")"
CLICKS_DELTA_HTML="$(fmt_delta "$CLICKS_DELTA")"
IMPRESSIONS_DELTA_HTML="$(fmt_delta "$IMPRESSIONS_DELTA")"
CTR_DELTA_HTML="$(fmt_delta "$CTR_DELTA")"

# Position delta is inverted (lower = better)
POS_DELTA_FMT="$(python3 -c "
v = float('$AVG_POS_DELTA')
if v < 0:
    print('<span class=\"delta positive\">&#9650; ' + str(abs(v)) + ' pos</span>')
elif v > 0:
    print('<span class=\"delta negative\">&#9660; ' + str(v) + ' pos</span>')
else:
    print('<span class=\"delta neutral\">&#9644; No change</span>')
" 2>/dev/null || echo "")"

# ---------------------------------------------------------------------------
# Audit scores
# ---------------------------------------------------------------------------
HEALTH_SCORE="$(jq_get '.audit.health_score.value')"
HEALTH_DELTA="$(jq_get '.audit.health_score.delta')"
CRITICAL_ERRORS="$(jq_get '.audit.critical_errors')"
WARNINGS="$(jq_get '.audit.warnings')"
NOTICES="$(jq_get '.audit.notices')"

# Health score color
HEALTH_COLOR="$(python3 -c "
s = int(float('$HEALTH_SCORE'))
if s >= 80: print('#22c55e')
elif s >= 60: print('#f59e0b')
else: print('#ef4444')
" 2>/dev/null || echo "#22c55e")"

HEALTH_DELTA_HTML="$(fmt_delta "$HEALTH_DELTA")"

# ---------------------------------------------------------------------------
# Build HTML tables from JSON arrays
# ---------------------------------------------------------------------------

# Top pages table
TOP_PAGES_HTML="$(jq -r '.gsc.top_pages[] |
  "<tr><td class=\"url-cell\"><a href=\"https://{{CLIENT_DOMAIN}}" + .url + "\" target=\"_blank\">" + .url + "</a></td><td>" +
  (.clicks | tostring) + "</td><td>" +
  (.impressions | tostring) + "</td><td>" +
  (.ctr | tostring) + "%</td><td>" +
  (.position | tostring) + "</td></tr>"
' "$DATA_FILE" | sed "s|{{CLIENT_DOMAIN}}|${CLIENT_DOMAIN}|g")"

# Top keywords table
TOP_KEYWORDS_HTML="$(jq -r '.gsc.top_keywords[] |
  "<tr><td>" + .query + "</td><td>" +
  (.clicks | tostring) + "</td><td>" +
  (.impressions | tostring) + "</td><td>" +
  (.ctr | tostring) + "%</td><td>" +
  (.position | tostring) + "</td><td>" +
  (if .prev_position then (.prev_position | tostring) else "—" end) + "</td></tr>"
' "$DATA_FILE")"

# Technical issues table
ISSUES_HTML="$(jq -r '.audit.top_issues[] |
  "<tr class=\"severity-" + .severity + "\"><td>" + .type + "</td><td>" +
  (.count | tostring) + "</td><td><span class=\"badge badge-" + .severity + "\">" +
  .severity + "</span></td></tr>"
' "$DATA_FILE")"

# Rankings table
RANKINGS_HTML="$(jq -r '.rankings[] |
  "<tr><td>" + .keyword + "</td><td class=\"pos-cell\">" +
  (.position | tostring) + "</td><td class=\"pos-cell\">" +
  (.prev_position | tostring) + "</td><td class=\"change-cell " +
  (if .change > 0 then "positive" elif .change < 0 then "negative" else "neutral" end) + "\">" +
  (if .change > 0 then "&#9650; " + (.change | tostring) elif .change < 0 then "&#9660; " + ((.change * -1) | tostring) else "&#9644; —" end) +
  "</td><td class=\"url-cell\">" + (.url // "—") + "</td></tr>"
' "$DATA_FILE")"

# Recommendations list
RECOMMENDATIONS_HTML="$(jq -r '.recommendations[] | "<li>" + . + "</li>"' "$DATA_FILE")"

# Next steps list
NEXT_STEPS_HTML="$(jq -r '.next_steps[] | "<li>" + . + "</li>"' "$DATA_FILE")"

# Executive summary bullets (auto-generated from deltas if not provided)
EXEC_SUMMARY_BULLETS="$(jq -r '
  if .executive_summary then
    .executive_summary[] | "<li>" + . + "</li>"
  else empty end
' "$DATA_FILE")"

if [[ -z "$EXEC_SUMMARY_BULLETS" ]]; then
  EXEC_SUMMARY_BULLETS="<li>Organic clicks reached <strong>$(fmt_num "$CLICKS")</strong> in $REPORT_MONTH — a <strong>${CLICKS_DELTA}%</strong> change vs. $PREV_MONTH.</li>
<li>Average search position improved to <strong>$AVG_POS</strong> (${AVG_POS_DELTA} vs. prior month).</li>
<li>Site health score is <strong>$HEALTH_SCORE/100</strong> with $CRITICAL_ERRORS critical errors requiring attention.</li>"
fi

# ---------------------------------------------------------------------------
# Logo HTML
# ---------------------------------------------------------------------------
if [[ -n "$LOGO_DATA_URI" ]]; then
  LOGO_HTML="<img src=\"${LOGO_DATA_URI}\" alt=\"${CLIENT_NAME} logo\" class=\"client-logo\">"
else
  LOGO_HTML="<span class=\"logo-text\">${CLIENT_NAME}</span>"
fi

# ---------------------------------------------------------------------------
# Stamp generation date
# ---------------------------------------------------------------------------
GENERATED_DATE="$(date '+%B %d, %Y')"

# ---------------------------------------------------------------------------
# Token substitution — write the filled template to output
# ---------------------------------------------------------------------------
echo "Rendering template..."

sed \
  -e "s|{{CLIENT_NAME}}|${CLIENT_NAME}|g" \
  -e "s|{{CLIENT_DOMAIN}}|${CLIENT_DOMAIN}|g" \
  -e "s|{{REPORT_MONTH}}|${REPORT_MONTH}|g" \
  -e "s|{{REPORT_YEAR}}|${REPORT_YEAR}|g" \
  -e "s|{{PREV_MONTH}}|${PREV_MONTH}|g" \
  -e "s|{{BRAND_COLOR}}|${BRAND_COLOR}|g" \
  -e "s|{{ACCENT_COLOR}}|${ACCENT_COLOR}|g" \
  -e "s|{{LOGO_HTML}}|${LOGO_HTML}|g" \
  -e "s|{{GENERATED_DATE}}|${GENERATED_DATE}|g" \
  -e "s|{{CLICKS}}|${CLICKS_FMT}|g" \
  -e "s|{{CLICKS_DELTA}}|${CLICKS_DELTA_HTML}|g" \
  -e "s|{{IMPRESSIONS}}|${IMPRESSIONS_FMT}|g" \
  -e "s|{{IMPRESSIONS_DELTA}}|${IMPRESSIONS_DELTA_HTML}|g" \
  -e "s|{{CTR}}|${CTR}%|g" \
  -e "s|{{CTR_DELTA}}|${CTR_DELTA_HTML}|g" \
  -e "s|{{AVG_POSITION}}|${AVG_POS}|g" \
  -e "s|{{POSITION_DELTA}}|${POS_DELTA_FMT}|g" \
  -e "s|{{HEALTH_SCORE}}|${HEALTH_SCORE}|g" \
  -e "s|{{HEALTH_COLOR}}|${HEALTH_COLOR}|g" \
  -e "s|{{HEALTH_DELTA}}|${HEALTH_DELTA_HTML}|g" \
  -e "s|{{CRITICAL_ERRORS}}|${CRITICAL_ERRORS}|g" \
  -e "s|{{WARNINGS}}|${WARNINGS}|g" \
  -e "s|{{NOTICES}}|${NOTICES}|g" \
  "$TEMPLATE" > "$OUT_HTML.tmp"

# Multi-line substitutions via Python (sed can't handle newlines in replacement)
python3 - "$OUT_HTML.tmp" "$OUT_HTML" <<PYEOF
import sys, re

with open(sys.argv[1], 'r') as f:
    content = f.read()

replacements = {
    '{{EXEC_SUMMARY_BULLETS}}': """${EXEC_SUMMARY_BULLETS}""",
    '{{TOP_PAGES_ROWS}}':       """${TOP_PAGES_HTML}""",
    '{{TOP_KEYWORDS_ROWS}}':    """${TOP_KEYWORDS_HTML}""",
    '{{ISSUES_ROWS}}':          """${ISSUES_HTML}""",
    '{{RANKINGS_ROWS}}':        """${RANKINGS_HTML}""",
    '{{RECOMMENDATIONS_ITEMS}}':"""${RECOMMENDATIONS_HTML}""",
    '{{NEXT_STEPS_ITEMS}}':     """${NEXT_STEPS_HTML}""",
}

for token, value in replacements.items():
    content = content.replace(token, value)

with open(sys.argv[2], 'w') as f:
    f.write(content)
PYEOF

rm -f "$OUT_HTML.tmp"

echo ""
echo "Report generated successfully."
echo "  HTML: $OUT_HTML"
echo ""
echo "Next: run 'bash scripts/pdf-export.sh' to convert to PDF."
echo "  Or set OUT_HTML=\"$OUT_HTML\" bash scripts/pdf-export.sh"
