#!/Users/mattsartori/.openclaw/workspace/skills/seo/.venv/bin/python3
"""
fetch_page.py — Fetch a URL and return clean markdown content.

Uses Jina Reader (r.jina.ai) by default to get clean markdown directly
instead of processing raw HTML/CSS. Falls back to direct requests + BeautifulSoup
if Jina fails or is unavailable.

Usage:
    python3 fetch_page.py <url> [--raw] [--no-jina]
"""

import sys
import requests
from urllib.parse import urlparse, quote

def fetch_via_markdown_new(url: str, timeout: int = 15) -> str | None:
    """Fetch URL via markdown.new — Cloudflare-powered, 80% fewer tokens than HTML.
    Three-tier fallback: native text/markdown → Workers AI → browser rendering."""
    md_url = f"https://markdown.new/{url}"
    headers = {"Accept": "text/markdown"}
    try:
        resp = requests.get(md_url, headers=headers, timeout=timeout + 5)
        if resp.status_code == 200:
            tokens = resp.headers.get("x-markdown-tokens", "unknown")
            print(f"[fetch_page] markdown.new: ~{tokens} tokens", file=sys.stderr)
            return resp.text
    except Exception as e:
        print(f"[fetch_page] markdown.new fetch failed: {e}", file=sys.stderr)
    return None


def fetch_direct(url: str, timeout: int = 15) -> str | None:
    """Fallback: fetch raw HTML and extract text via BeautifulSoup."""
    try:
        from bs4 import BeautifulSoup
        headers = {"User-Agent": "Mozilla/5.0 (compatible; SEO-Audit/1.0)"}
        resp = requests.get(url, headers=headers, timeout=timeout)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")

        # Remove noise
        for tag in soup(["script", "style", "nav", "footer", "header", "iframe", "noscript"]):
            tag.decompose()

        # Extract main content
        main = soup.find("main") or soup.find("article") or soup.find("body")
        return main.get_text(separator="\n", strip=True) if main else soup.get_text(separator="\n", strip=True)
    except Exception as e:
        print(f"[fetch_page] Direct fetch failed: {e}", file=sys.stderr)
    return None


def fetch(url: str, use_jina: bool = True, timeout: int = 15) -> str:
    """Fetch a URL as clean markdown. Tries markdown.new first, falls back to direct."""
    if use_jina:  # flag kept for compat, now uses markdown.new
        result = fetch_via_markdown_new(url, timeout)
        if result:
            return result
        print(f"[fetch_page] Falling back to direct fetch for {url}", file=sys.stderr)

    result = fetch_direct(url, timeout)
    if result:
        return result

    return f"[ERROR] Could not fetch {url}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: fetch_page.py <url> [--raw] [--no-jina]")
        sys.exit(1)

    url = sys.argv[1]
    use_jina = "--no-jina" not in sys.argv

    content = fetch(url, use_jina=use_jina)
    print(content)
