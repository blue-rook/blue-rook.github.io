#!/usr/bin/env bash
# test-reorg.sh — Validate repo reorganization before committing.
# Run once, then delete: chmod +x test-reorg.sh && ./test-reorg.sh

set -euo pipefail

PASS=0
FAIL=0

pass() { ((PASS++)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { ((FAIL++)); printf "  \033[31m✗\033[0m %s\n" "$1"; }

check_exists()    { [[ -e "$1" ]] && pass "$1 exists"          || fail "$1 missing"; }
check_not_exists(){ [[ ! -e "$1" ]] && pass "$1 removed"       || fail "$1 still present"; }
check_contains()  { grep -q "$2" "$1" 2>/dev/null && pass "$1 contains '$2'" || fail "$1 missing '$2'"; }
check_not_contains(){ ! grep -q "$2" "$1" 2>/dev/null && pass "$1 does NOT contain '$2'" || fail "$1 unexpectedly contains '$2'"; }

# ── 1. Repo structure — files exist where expected ──────────────────────────
echo ""
echo "── 1. Repo structure ──"
check_exists hugo.toml
check_exists go.mod
check_exists go.sum
check_exists content/blog/my-new-post/index.md
check_exists content/blog/poesia-distraida/index.md
check_exists archetypes/default.md
check_exists static/favicon.ico
check_exists .gitignore
check_exists .github/workflows/hugo.yaml
check_exists Makefile
check_exists CLAUDE.md

# ── 2. Old structure is gone ────────────────────────────────────────────────
echo ""
echo "── 2. Old structure removed ──"
check_not_exists .hugo
check_not_exists index.html
check_not_exists 404.html
check_not_exists sitemap.xml
check_not_exists blog
check_not_exists css
check_not_exists fonts
check_not_exists categories
check_not_exists tags

# ── 3. Hugo build succeeds ──────────────────────────────────────────────────
echo ""
echo "── 3. Hugo build ──"
# Clean first to ensure a fresh build
rm -rf public/ resources/_gen/

if hugo --gc --minify > /dev/null 2>&1; then
  pass "hugo --gc --minify exits 0"
else
  fail "hugo --gc --minify failed"
fi

check_exists public
check_exists public/index.html
check_exists public/blog/index.html
check_exists public/blog/my-new-post/index.html
check_exists public/blog/poesia-distraida/index.html
check_exists public/sitemap.xml
check_exists public/index.xml
check_exists public/404.html

# ── 4. Content integrity — generated HTML ────────────────────────────────────
echo ""
echo "── 4. Content integrity ──"
check_contains public/index.html "Blue rook technology"
check_contains public/index.html "docs.google.com/forms"
check_contains public/index.html "&copy; 2026 Blue rook technology"
check_not_contains public/index.html "Built with Hugo"
check_contains public/blog/index.html "my-new-post"
check_contains public/blog/index.html "poesia-distraida"
check_contains public/blog/my-new-post/index.html "Laurinha"
check_contains public/blog/my-new-post/index.html "Adão"
check_contains public/blog/poesia-distraida/index.html "distraída"
check_contains public/blog/poesia-distraida/index.html "potência"

# ── 5. Config integrity ─────────────────────────────────────────────────────
echo ""
echo "── 5. Config integrity ──"
HUGO_CFG=$(hugo config 2>/dev/null)

if echo "$HUGO_CFG" | grep -qi "baseurl.*blue-rook.github.io"; then
  pass "baseURL = blue-rook.github.io"
else
  fail "baseURL not set correctly"
fi

if echo "$HUGO_CFG" | grep -qi "footerhtml"; then
  pass "footerHtml param present"
else
  fail "footerHtml param missing"
fi

if echo "$HUGO_CFG" | grep -qi "docs.google.com/forms"; then
  pass "Google Forms URL in social params"
else
  fail "Google Forms URL missing from config"
fi

# ── 6. .gitignore works ─────────────────────────────────────────────────────
echo ""
echo "── 6. .gitignore ──"
GIT_STATUS=$(git status --porcelain 2>/dev/null)

if echo "$GIT_STATUS" | grep -q "^?? public/"; then
  fail "public/ shows as untracked"
else
  pass "public/ is gitignored"
fi

if echo "$GIT_STATUS" | grep -q "^?? resources/_gen/"; then
  fail "resources/_gen/ shows as untracked"
else
  pass "resources/_gen/ is gitignored"
fi

# ── 7. Makefile targets ─────────────────────────────────────────────────────
echo ""
echo "── 7. Makefile targets ──"

if make help > /dev/null 2>&1; then
  pass "make help"
else
  fail "make help"
fi

if make build > /dev/null 2>&1; then
  pass "make build"
else
  fail "make build"
fi

if make clean > /dev/null 2>&1 && [[ ! -d public ]] && [[ ! -d resources/_gen ]]; then
  pass "make clean removes artifacts"
else
  fail "make clean"
fi

# ── 8. GitHub Actions workflow ───────────────────────────────────────────────
echo ""
echo "── 8. GitHub Actions workflow ──"

if ruby -e "require 'yaml'; YAML.load_file('.github/workflows/hugo.yaml')" 2>/dev/null; then
  pass "hugo.yaml is valid YAML"
else
  fail "hugo.yaml is NOT valid YAML"
fi

if grep -q "master" .github/workflows/hugo.yaml; then
  pass "workflow triggers on master"
else
  fail "workflow does NOT trigger on master"
fi

if grep -q "hugo_extended" .github/workflows/hugo.yaml; then
  pass "workflow uses hugo_extended"
else
  fail "workflow does NOT reference hugo_extended"
fi

# ── Cleanup ──────────────────────────────────────────────────────────────────
echo ""
make clean > /dev/null 2>&1

# ── Summary ──────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL=$((PASS + FAIL))
printf "Results: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m out of %d\n" "$PASS" "$FAIL" "$TOTAL"

if [[ $FAIL -eq 0 ]]; then
  printf "\n\033[32mAll tests passed — safe to commit.\033[0m\n"
  exit 0
else
  printf "\n\033[31mSome tests failed — review before committing.\033[0m\n"
  exit 1
fi
