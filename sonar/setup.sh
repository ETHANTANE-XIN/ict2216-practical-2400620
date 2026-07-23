#!/bin/sh
set -eu

sonar_url=http://sonarqube:9000
admin_password="${SONAR_ADMIN_PASSWORD:?SONAR_ADMIN_PASSWORD is required}"
token_name=compose-scan-2400620

if ! curl -fsS \
  -u "admin:${admin_password}" \
  "${sonar_url}/api/authentication/validate" |
  grep -q '"valid":true'; then
  curl -fsS \
    -u admin:admin \
    -X POST \
    --data-urlencode "login=admin" \
    --data-urlencode "previousPassword=admin" \
    --data-urlencode "password=${admin_password}" \
    "${sonar_url}/api/users/change_password"
fi

curl -sS \
  -u "admin:${admin_password}" \
  -X POST \
  --data-urlencode "name=${token_name}" \
  "${sonar_url}/api/user_tokens/revoke" >/dev/null || true

token="$(
  curl -fsS \
    -u "admin:${admin_password}" \
    -X POST \
    --data-urlencode "name=${token_name}" \
    --data-urlencode "type=GLOBAL_ANALYSIS_TOKEN" \
    "${sonar_url}/api/user_tokens/generate" |
  jq -er '.token'
)"

umask 077
printf '%s' "$token" > /token/value
echo "SonarQube admin configured and scan token generated."
