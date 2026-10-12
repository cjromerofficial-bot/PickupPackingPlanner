#!/usr/bin/env bash
# Combines app.html + data.js + catalog.js into site/index.html (the deployed page).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p site
awk '/\/\*@@DATA@@\*\//{ system("cat data.js catalog.js"); next } 1' app.html > site/index.html
echo "Built site/index.html ($(wc -c < site/index.html) bytes)"
