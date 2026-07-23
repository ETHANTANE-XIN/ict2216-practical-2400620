#!/bin/sh
set -eu

admin_password="${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}"
admin_email="${ADMIN_EMAIL:?ADMIN_EMAIL is required}"
config=/data/gitea/conf/app.ini
repository=ict2216-practical-2400620

/usr/bin/entrypoint "$@" &
server_pid=$!

stop_server() {
  kill -TERM "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
}
trap stop_server INT TERM

attempt=0
until curl -fsS http://127.0.0.1:3000/api/healthz >/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 90 ]; then
    echo "Gitea did not become ready." >&2
    stop_server
    exit 1
  fi
  sleep 2
done

users="$(su-exec git gitea admin user list --config "$config")"
if printf '%s\n' "$users" | grep -Eq '^[0-9]+[[:space:]]+admin[[:space:]]'; then
  su-exec git gitea admin user change-password \
    --config "$config" \
    --username admin \
    --password "$admin_password" \
    --must-change-password=false
else
  su-exec git gitea admin user create \
    --config "$config" \
    --username admin \
    --password "$admin_password" \
    --email "$admin_email" \
    --admin \
    --must-change-password=false
fi

http_code="$(
  curl -sS \
    -o /tmp/gitea-repository.json \
    -w '%{http_code}' \
    -u "admin:${admin_password}" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"${repository}\",\"private\":false}" \
    http://127.0.0.1:3000/api/v1/user/repos
)"
if [ "$http_code" != "201" ] && [ "$http_code" != "409" ]; then
  cat /tmp/gitea-repository.json >&2
  stop_server
  exit 1
fi

work_directory="$(mktemp -d)"
cp -a /seed/. "$work_directory/"
rm -rf \
  "$work_directory/.git" \
  "$work_directory/.scannerwork" \
  "$work_directory/coverage" \
  "$work_directory/node_modules" \
  "$work_directory/reports"

git -C "$work_directory" init -b main
git -C "$work_directory" config user.name "ETHAN TAN E-XIN"
git -C "$work_directory" config user.email "$admin_email"
git -C "$work_directory" add -A
git -C "$work_directory" commit -m "Complete ICT2216 practical lab submission"

basic_auth="$(
  printf 'admin:%s' "$admin_password" | base64 | tr -d '\r\n'
)"
git -C "$work_directory" \
  -c "http.extraHeader=Authorization: Basic ${basic_auth}" \
  push --force \
  "http://127.0.0.1:3000/admin/${repository}.git" \
  main

rm -rf "$work_directory"
echo "Gitea repository seeded: admin/${repository}"

wait "$server_pid"
