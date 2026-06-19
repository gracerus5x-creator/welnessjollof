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

if ! grep -qE 'class="?product-card"?' "$PAGE"; then
  echo "FAIL: product-card wrapper not rendered"; exit 1
fi
if ! grep -q '\$41.00' "$PAGE"; then
  echo "FAIL: ALA price \$41.00 not in card"; exit 1
fi
if ! grep -q 'price approximate — check iHerb' "$PAGE"; then
  echo "FAIL: price-approximate note missing"; exit 1
fi
# Behaviour change (commit 59e0b8a): GH Pages runs Hugo only, never the
# pipeline affiliate_resolver. So the shortcode builds the canonical iHerb
# URL at Hugo build time from iherb_canonical_url + iherb_rcode. The
# AFFILIATE_LINK_PLACEHOLDER pattern must NOT appear in rendered HTML.
if ! grep -q 'iherb.com/pr/thorne-alpha-lipoic-acid' "$PAGE"; then
  echo "FAIL: canonical iHerb URL missing — shortcode failed to resolve iherb_canonical_url"; exit 1
fi
if ! grep -q 'rcode=PFR1152' "$PAGE"; then
  echo "FAIL: affiliate rcode not appended — hugo.toml iherb_rcode missing or shortcode broken"; exit 1
fi
if grep -q 'AFFILIATE_LINK_PLACEHOLDER' "$PAGE"; then
  echo "FAIL: placeholder leaked into rendered HTML — shortcode regression"; exit 1
fi
# rel attributes must be present for SEO + FTC
if ! grep -qE 'rel="?nofollow sponsored noopener"?' "$PAGE"; then
  echo "FAIL: rel attributes missing on CTA"; exit 1
fi

echo "PASS: product shortcode smoke test"
