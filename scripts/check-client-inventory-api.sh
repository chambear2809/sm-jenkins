#!/usr/bin/env bash
set -euo pipefail

OPENAPI_SPEC="${OPENAPI_SPEC:-openapi.json}"
API_BASE_URL="${API_BASE_URL:-}"
SF_API_TOKEN="${SF_API_TOKEN:-}"
API_CHECK_RETRIES="${API_CHECK_RETRIES:-3}"
API_CHECK_RETRY_DELAY_SECONDS="${API_CHECK_RETRY_DELAY_SECONDS:-5}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

case "$API_CHECK_RETRIES" in
  ''|*[!0-9]*) fail "API_CHECK_RETRIES must be a positive integer" ;;
esac

case "$API_CHECK_RETRY_DELAY_SECONDS" in
  ''|*[!0-9]*) fail "API_CHECK_RETRY_DELAY_SECONDS must be a positive integer" ;;
esac

[ "$API_CHECK_RETRIES" -ge 1 ] || fail "API_CHECK_RETRIES must be at least 1"
[ -n "$API_BASE_URL" ] || fail "API_BASE_URL is required"
[ -n "$SF_API_TOKEN" ] || fail "SF_API_TOKEN is required"
[ -x "$(command -v curl)" ] || fail "curl is required on the Jenkins agent"
[ -f "$OPENAPI_SPEC" ] || fail "OpenAPI spec not found: $OPENAPI_SPEC"

grep -q '"openapi"' "$OPENAPI_SPEC" || fail "$OPENAPI_SPEC does not look like an OpenAPI document"
grep -q '"/clients"' "$OPENAPI_SPEC" || fail "$OPENAPI_SPEC does not define /clients"

base_url="${API_BASE_URL%/}"
url="${base_url}/clients?limit=1&offset=0&include_health=false"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

attempt=1
while [ "$attempt" -le "$API_CHECK_RETRIES" ]; do
  http_code="$(
    curl --silent --show-error \
      --connect-timeout 10 \
      --max-time 30 \
      --output "$response_file" \
      --write-out '%{http_code}' \
      --header "X-SF-Token: ${SF_API_TOKEN}" \
      --header "Accept: application/json" \
      "$url" || true
  )"

  if printf '%s' "$http_code" | grep -Eq '^2[0-9][0-9]$'; then
    first_char="$(awk 'BEGIN { RS = "" } { gsub(/[[:space:]]/, ""); print substr($0, 1, 1); exit }' "$response_file")"
    if [ "$first_char" = "{" ] || [ "$first_char" = "[" ]; then
      printf 'Client Inventory API check passed: GET %s returned HTTP %s\n' "$url" "$http_code"
      exit 0
    fi

    printf 'Attempt %s/%s returned HTTP %s but response was not JSON\n' "$attempt" "$API_CHECK_RETRIES" "$http_code" >&2
  else
    printf 'Attempt %s/%s failed: GET %s returned HTTP %s\n' "$attempt" "$API_CHECK_RETRIES" "$url" "${http_code:-000}" >&2
  fi

  if [ "$attempt" -lt "$API_CHECK_RETRIES" ]; then
    sleep "$API_CHECK_RETRY_DELAY_SECONDS"
  fi
  attempt=$((attempt + 1))
done

printf 'Last response body:\n' >&2
sed -n '1,40p' "$response_file" >&2
fail "Client Inventory API check failed after ${API_CHECK_RETRIES} attempt(s)"
