#!/usr/bin/env bash
set -e
set -o pipefail

su - deploy <<'EOF'
rm -rf /home/deploy/bops/current/.bundle
rm -f /home/deploy/bops/current/log
rm -f /home/deploy/bops/current/tmp
rm -f /home/deploy/bops/current/vendor/bundle
rm -f /home/deploy/bops/current/public/packs
rm -rf /home/deploy/bops/current/node_modules
EOF
