#!/usr/bin/env bash
# =============================================================================
# pdf-export.sh — Convert an SEO report HTML file to PDF
# =============================================================================
# Usage:
#   bash scripts/pdf-export.sh [path/to/report.html]
#
#   If no argument is given, the script looks for the most recently modified
#   HTML file under workspace/reports/**/*.html
#
# Tool priority:
#   1. wkhtmltopdf  (preferred — best CSS support for print layouts)
#   2. Puppeteer    (Node.js — fallback via npx or global install)
#   3. Manual       (prints instructions for browser print-to-PDF)
#
# Output:
#   Same directory as the HTML, with .pdf extension.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORTS_BASE="${SKILL_DIR}/../../../reports"

# ---------------------------------------------------------------------------
# Resolve input HTML path
# ---------------------------------------------------------------------------
if [[ $# -ge 1 ]]; then
  HTML_FILE="$(realpath "$1")"
else
  # Find the most recently modified HTML report
  if [[ ! -d "$REPORTS_BASE" ]]; then
    echo "ERROR: No reports directory found at: $REPORTS_BASE"
    echo "  Run 'bash scripts/generate-report.sh' first."
    exit 1
  fi
  HTML_FILE="$(find "$REPORTS_BASE" -name '*.html' -printf '%T@ %p\n' 2>/dev/null \
    | sort -n | tail -1 | awk '{print $2}')"
  if [[ -z "$HTML_FILE" ]]; then
    echo "ERROR: No HTML report found under: $REPORTS_BASE"
    echo "  Run 'bash scripts/generate-report.sh' first."
    exit 1
  fi
  echo "Auto-detected report: $HTML_FILE"
fi

if [[ ! -f "$HTML_FILE" ]]; then
  echo "ERROR: HTML file not found: $HTML_FILE"
  exit 1
fi

PDF_FILE="${HTML_FILE%.html}.pdf"
HTML_ABS="$(realpath "$HTML_FILE")"

echo "Input  : $HTML_ABS"
echo "Output : $PDF_FILE"
echo ""

# ---------------------------------------------------------------------------
# Helper: success message
# ---------------------------------------------------------------------------
success() {
  echo ""
  echo "PDF exported successfully."
  echo "  $PDF_FILE"
  echo ""
  echo "Open with:"
  echo "  open \"$PDF_FILE\""
}

# ---------------------------------------------------------------------------
# Method 1: wkhtmltopdf
# ---------------------------------------------------------------------------
if command -v wkhtmltopdf &>/dev/null; then
  echo "Using: wkhtmltopdf"
  wkhtmltopdf \
    --page-size A4 \
    --orientation Portrait \
    --margin-top    0mm \
    --margin-right  0mm \
    --margin-bottom 0mm \
    --margin-left   0mm \
    --encoding UTF-8 \
    --enable-local-file-access \
    --print-media-type \
    --disable-smart-shrinking \
    --zoom 1.0 \
    --dpi 150 \
    --no-background \
    "file://${HTML_ABS}" \
    "$PDF_FILE"
  success
  exit 0
fi

# ---------------------------------------------------------------------------
# Method 2: Puppeteer (via npx — no global install required)
# ---------------------------------------------------------------------------
if command -v node &>/dev/null; then
  echo "wkhtmltopdf not found — trying Puppeteer via Node.js..."

  # Write a temporary Puppeteer script
  PUPPET_SCRIPT="$(mktemp /tmp/seo-pdf-export-XXXXXX.mjs)"
  trap 'rm -f "$PUPPET_SCRIPT"' EXIT

  cat > "$PUPPET_SCRIPT" <<'PUPPET'
import puppeteer from 'puppeteer';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const htmlPath = process.argv[2];
const pdfPath  = process.argv[3];

if (!htmlPath || !pdfPath) {
  console.error('Usage: node script.mjs <html> <pdf>');
  process.exit(1);
}

const absHtml = resolve(htmlPath);
const fileUrl = `file://${absHtml}`;

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--allow-file-access-from-files'],
  });

  try {
    const page = await browser.newPage();
    await page.goto(fileUrl, { waitUntil: 'networkidle0', timeout: 30000 });

    // Wait for any CSS animations/transitions to settle
    await new Promise(r => setTimeout(r, 800));

    await page.pdf({
      path: pdfPath,
      format: 'A4',
      printBackground: true,
      preferCSSPageSize: false,
      margin: { top: 0, right: 0, bottom: 0, left: 0 },
    });

    console.log(`PDF written: ${pdfPath}`);
  } finally {
    await browser.close();
  }
})();
PUPPET

  # Try npx puppeteer (installs on demand if not present)
  if npx --yes puppeteer@latest --version &>/dev/null 2>&1; then
    echo "Using: npx puppeteer"
    node "$PUPPET_SCRIPT" "$HTML_ABS" "$PDF_FILE"
    success
    exit 0
  fi

  # Try globally installed puppeteer-cli
  if command -v puppeteer &>/dev/null; then
    echo "Using: puppeteer-cli (global)"
    puppeteer pdf \
      --output "$PDF_FILE" \
      --format A4 \
      --print-background \
      "file://${HTML_ABS}"
    success
    exit 0
  fi

  # Try project-local puppeteer
  if [[ -f "node_modules/.bin/puppeteer" ]]; then
    echo "Using: local puppeteer"
    node "$PUPPET_SCRIPT" "$HTML_ABS" "$PDF_FILE"
    success
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Method 3: Manual browser fallback
# ---------------------------------------------------------------------------
echo "=====================================================================";
echo "  Neither wkhtmltopdf nor Puppeteer is available."
echo "=====================================================================";
echo ""
echo "To install wkhtmltopdf (recommended):"
echo "  macOS:  brew install wkhtmltopdf"
echo "  Linux:  sudo apt-get install -y wkhtmltopdf"
echo ""
echo "To install Puppeteer:"
echo "  npm install -g puppeteer"
echo "  # or use: npx puppeteer"
echo ""
echo "Manual export (Chrome/Edge/Safari):"
echo "  1. Open the HTML file in your browser:"
echo "     open \"$HTML_ABS\""
echo "  2. Print (Cmd+P / Ctrl+P)"
echo "  3. Select 'Save as PDF', Paper: A4, Margins: None"
echo "  4. Save to: $PDF_FILE"
echo ""
echo "HTML report is ready at:"
echo "  $HTML_ABS"
exit 1
