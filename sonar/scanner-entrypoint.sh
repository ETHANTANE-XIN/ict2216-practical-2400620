#!/bin/sh
set -eu

attempt=0
until [ -s /token/value ]; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 300 ]; then
    echo "SonarQube scan token was not generated." >&2
    exit 1
  fi
  sleep 1
done

sonar_token="$(cat /token/value)"
sonar-scanner-npm \
  -Dsonar.token="$sonar_token" \
  -Dsonar.qualitygate.wait=true

project_key=ict2216-practical-2400620
sonar_auth="admin:${SONAR_ADMIN_PASSWORD:?SONAR_ADMIN_PASSWORD is required}"

bugs="$(
  curl -fsS -u "$sonar_auth" \
    "${SONAR_HOST_URL}/api/issues/search?componentKeys=${project_key}&types=BUG&resolved=false&ps=1" |
    jq -er '.total'
)"
vulnerabilities="$(
  curl -fsS -u "$sonar_auth" \
    "${SONAR_HOST_URL}/api/issues/search?componentKeys=${project_key}&types=VULNERABILITY&resolved=false&ps=1" |
    jq -er '.total'
)"
security_hotspots="$(
  curl -fsS -u "$sonar_auth" \
    "${SONAR_HOST_URL}/api/hotspots/search?projectKey=${project_key}&status=TO_REVIEW&ps=1" |
    jq -er '.paging.total'
)"

echo "SonarQube verification: bugs=${bugs}, vulnerabilities=${vulnerabilities}, security_hotspots=${security_hotspots}"
if [ "$bugs" -ne 0 ] ||
  [ "$vulnerabilities" -ne 0 ] ||
  [ "$security_hotspots" -ne 0 ]; then
  echo "SonarQube still reports unresolved findings." >&2
  exit 1
fi
