#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
rm -rf Web
mkdir -p Web/vendor
cp ../web-prototype/index.html Web/
cp ../web-prototype/app.js Web/
cp ../web-prototype/native.js Web/
cp ../web-prototype/native-player.js Web/
cp ../web-prototype/styles.css Web/
cp ../web-prototype/fonts.css Web/
cp ../web-prototype/vendor/hls.min.js Web/vendor/
