#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TMPCONTENT="content/posts/_disclosure_test.md"
TMPBUILD="$(mktemp -d)"
trap "rm -f $TMPCONTENT; rm -rf $TMPBUILD" EXIT

cat > "$TMPCONTENT" <<'EOF'
---
title: "Disclosure test"
draft: false
---
<div class="disclosure"><strong>Affiliate disclosure:</strong> If you buy a product through a link on this page we may earn a small commission at no extra cost to you.</div>

<div class="medical-disclaimer">This content is for informational purposes only. Consult your healthcare provider before making any changes to your treatment plan.</div>
EOF

hugo --destination "$TMPBUILD" --quiet

# Static SVGs must be served at the absolute URL the CSS references
if [ ! -f "$TMPBUILD/doodles/warning-triangle.svg" ]; then
  echo "FAIL: static/doodles/warning-triangle.svg not deployed"; exit 1
fi
if [ ! -f "$TMPBUILD/doodles/lab-coat.svg" ]; then
  echo "FAIL: static/doodles/lab-coat.svg not deployed"; exit 1
fi

# brand.css must reference the two URLs
CSS_FILE="$(find $TMPBUILD -name 'brand.*.min.css' -o -name 'brand.*.css' | head -1)"
if [ -z "$CSS_FILE" ]; then echo "FAIL: brand css fingerprint not found"; exit 1; fi
if ! grep -q 'warning-triangle.svg' "$CSS_FILE"; then
  echo "FAIL: warning-triangle ref missing from compiled CSS"; exit 1
fi

echo "PASS: disclosure prefix smoke test"
