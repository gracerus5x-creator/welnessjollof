#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Create a throwaway test page that exercises the shortcode
TMPCONTENT="content/posts/_doodle_test.md"
TMPBUILD="$(mktemp -d)"
trap "rm -f $TMPCONTENT; rm -rf $TMPBUILD" EXIT

cat > "$TMPCONTENT" <<'EOF'
---
title: "Doodle test"
draft: false
---
{{< doodle name="neuron" size="medium" align="right" >}}
{{< doodle name="lab-coat" size="small" >}}
EOF

hugo --destination "$TMPBUILD" --quiet

PAGE="$TMPBUILD/posts/_doodle_test/index.html"

if ! grep -q 'class="doodle-inline doodle-inline--medium doodle-inline--right"' "$PAGE"; then
  echo "FAIL: medium/right doodle wrapper not rendered"; exit 1
fi
if ! grep -q '<svg' "$PAGE"; then
  echo "FAIL: inlined SVG content not present"; exit 1
fi
# Must NOT contain any hex colours (assets were recoloured to currentColor)
if grep -Eq 'fill="#[0-9a-fA-F]' "$PAGE"; then
  echo "FAIL: hex fill leaked into rendered output"; exit 1
fi

echo "PASS: doodle shortcode smoke test"
