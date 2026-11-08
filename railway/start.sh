#!/bin/sh
set -eu
case "${MOLI_TOKEN:-}" in
  ""|*[!A-Za-z0-9_-]*) echo "MOLI_TOKEN must be set (letters, digits, - and _ only)." >&2; exit 1 ;;
esac
if [ "${#MOLI_TOKEN}" -lt 16 ]; then echo "MOLI_TOKEN must be at least 16 characters." >&2; exit 1; fi
export PORT MOLI_INTERNAL_PORT MOLI_TOKEN
envsubst '${PORT} ${MOLI_INTERNAL_PORT} ${MOLI_TOKEN}' < /etc/moli-railway/nginx.conf.template > /tmp/nginx.conf
nginx -t -c /tmp/nginx.conf -q

# shellcheck disable=SC2086
su moli -s /bin/sh -c "exec /usr/local/bin/moli serve --host 127.0.0.1 --port $MOLI_INTERNAL_PORT $MOLI_SERVE_ARGS" &
MOLI_PID=$!
nginx -c /tmp/nginx.conf &
NGINX_PID=$!
echo "Moli endpoint: https://${RAILWAY_PUBLIC_DOMAIN:-<your-domain>}/t/<MOLI_TOKEN>"

trap 'kill $MOLI_PID $NGINX_PID 2>/dev/null; exit 0' TERM INT
while kill -0 "$MOLI_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do sleep 5; done
echo "moli or nginx exited" >&2
kill $MOLI_PID $NGINX_PID 2>/dev/null || true
exit 1
