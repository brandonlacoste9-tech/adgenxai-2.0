#!/usr/bin/env python3
"""
Soft site guard:
- Warn if changed HTML files are missing a canonical tag.
- Warn if added HTML files aren't listed in public/sitemap.xml.
- Nudge for OG/Twitter meta on likely-shareable pages (index, compare, pricing).
Soft by default (exit 0). Set env STRICT=1 to fail on errors.
"""
from __future__ import annotations
import os, re, sys, pathlib, xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
PUBLIC = ROOT / "public"
SITEMAP = PUBLIC / "sitemap.xml"

CHANGED = ROOT / "changed.txt"
ADDED   = ROOT / "added.txt"

HTML_CANONICAL = re.compile(
    r'<link[^>]+rel=["\']canonical["\'][^>]*href=["\'](?P<href>[^"\']+)["\']',
    re.IGNORECASE | re.DOTALL,
)
OG_PRESENT = re.compile(r'<meta[^>]+property=["\']og:', re.IGNORECASE)
TW_PRESENT = re.compile(r'<meta[^>]+name=["\']twitter:', re.IGNORECASE)

def read_lines(p: pathlib.Path) -> list[str]:
    if not p.exists():
        return []
    return [ln.strip() for ln in p.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]

def list_html(paths: list[str]) -> list[pathlib.Path]:
    out: list[pathlib.Path] = []
    for rel in paths:
        p = (ROOT / rel).resolve()
        if p.suffix.lower() == ".html" and p.exists():
            out.append(p)
    return out

def load_sitemap_urls() -> set[str]:
    urls: set[str] = set()
    if not SITEMAP.exists():
        return urls
    try:
        tree = ET.parse(SITEMAP)
        for loc in tree.getroot().iter():
            if loc.tag.endswith("loc") and loc.text:
                urls.add(loc.text.strip())
    except Exception:
        pass
    return urls

def page_url_for(path: pathlib.Path) -> str:
    name = path.name
    route = "/" if name.lower() == "index.html" else f"/{name[:-5]}"
    return f"https://www.adgenxai.com{route}"

def warn(msg: str):
    print(f"::warning::{msg}")

def main() -> int:
    changed = list_html(read_lines(CHANGED))
    added   = list_html(read_lines(ADDED))
    if not changed and not added:
        changed = list_html([str(p.relative_to(ROOT)) for p in ROOT.glob("*.html")])
    sitemap_urls = load_sitemap_urls()
    had_errors = False

    # 1) Canonical checks for changed files
    for html in changed:
        txt = html.read_text(encoding="utf-8", errors="replace")
        m = HTML_CANONICAL.search(txt)
        if not m:
            warn(f"{html.relative_to(ROOT)} is missing <link rel=\"canonical\">")
            had_errors = True
        else:
            expected = page_url_for(html)
            href = m.group("href").strip()
            if href != expected:
                warn(f"{html.relative_to(ROOT)} canonical href mismatch: '{href}' != '{expected}'")
                had_errors = True

        # 2) OG/Twitter nudge on commonly shared pages
        sharey = html.name.lower() in {"index.html", "compare.html", "pricing.html"}
        if sharey and not (OG_PRESENT.search(txt) and TW_PRESENT.search(txt)):
            warn(f"{html.relative_to(ROOT)}: consider adding OG/Twitter meta for richer sharing cards")

    # 3) Sitemap must include new pages
    for html in added:
        url = page_url_for(html)
        if url not in sitemap_urls:
            warn(f"public/sitemap.xml missing <loc>{url}</loc> for new page '{html.name}'")
            had_errors = True

    # Soft by default; flip STRICT=1 to fail PR
    if os.getenv("STRICT", "0") == "1" and had_errors:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
