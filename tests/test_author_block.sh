#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Dry-build to a temp dir, then grep the rendered HTML
TMP="$(mktemp -d)"
trap "rm -rf $TMP" EXIT

hugo --destination "$TMP" --quiet

# Both articles must render the full author block exactly once
for f in alpha-lipoic-acid-benefits-for-neuropathy vitamin-b12-deficiency-symptoms-hair-loss; do
  COUNT="$(grep -c 'class="author-block"' "$TMP/posts/$f/index.html" || true)"
  if [ "$COUNT" -ne 1 ]; then
    echo "FAIL: $f has $COUNT author-block (expected 1)"; exit 1
  fi
done

# Footer compact variant must appear on every page — pick index.html as proxy
if ! grep -q 'class="author-block compact"' "$TMP/index.html"; then
  echo "FAIL: index.html missing compact author-block in footer"; exit 1
fi

# Real name must appear
if ! grep -q 'Augustine Usifo' "$TMP/index.html"; then
  echo "FAIL: realName not rendered"; exit 1
fi

echo "PASS: author_block smoke test"
