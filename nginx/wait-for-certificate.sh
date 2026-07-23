#!/bin/sh
set -eu

attempt=0
until [ -s /etc/nginx/certs/server.crt ] &&
  [ -s /etc/nginx/certs/server.key ]; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    echo "HTTPS certificate was not generated." >&2
    exit 1
  fi
  sleep 1
done

exec /docker-entrypoint.sh "$@"
