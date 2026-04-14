#!/bin/sh
# Generate runtime config from environment variables.
# Loaded before config.js so runtime values take precedence.

cat > /srv/site/runtime-config.js <<EOF
window.CR = window.CR || {};
CR.config = CR.config || {};
CR.config.API_BASE_URL = "${API_BASE_URL:-/api}";
CR.config.API_TOKEN = "${API_TOKEN:-}";
EOF

exec "$@"
