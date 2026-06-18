#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TMPCONTENT="content/posts/_product_test.md"
TMPBUILD="$(mktemp -d)"
trap "rm -f $TMPCONTENT; rm -rf $TMPBUILD" EXIT

cat > "$TMPCONTENT" <<'EOF'
---
title: "Product card test"
draft: false
---
{{< product name="alpha-lipoic-thorne" >}}
EOF

hugo --destination "$TMPBUILD" --quiet

PAGE="$TMPBUILD/posts/_product_test/index.html"

if ! grep -q 'class="product-card"' "$PAGE"; then
  echo "FAIL: product-card wrapper not rendered"; exit 1
fi
if ! grep -q '\$41.00' "$PAGE"; then
  echo "FAIL: ALA price \$41.00 not in card"; exit 1
fi
if ! grep -q 'price approximate — check iHerb' "$PAGE"; then
  echo "FAIL: price-approximate note missing"; exit 1
fi
# Resolver runs at PUBLISH time, not Hugo build time — placeholder MUST appear
# in the built HTML; affiliate_resolver.py rewrites it during step_06_publish.
if ! grep -q 'AFFILIATE_LINK_PLACEHOLDER:iherb:thorne-alpha-lipoic-acid' "$PAGE"; then
  echo "FAIL: affiliate placeholder not preserved (resolver runs at publish time)"; exit 1
fi
# rel attributes must be present for SEO + FTC
if ! grep -q 'rel="nofollow sponsored noopener"' "$PAGE"; then
  echo "FAIL: rel attributes missing on CTA"; exit 1
fi

echo "PASS: product shortcode smoke test"
