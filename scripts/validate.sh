#!/bin/sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
image="aduana-validation-$$:0.0.1"
scanner_image="aduana-vulncheck-$$:0.0.1"
validation_token=$(printf '%040d' 0)

cleanup() {
  rm -rf "$tmp_dir"
  docker image rm --force "$image" >/dev/null 2>&1 || true
  docker image rm --force "$scanner_image" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

cp "$root_dir/.env.example" "$tmp_dir/env"

docker compose \
  --project-directory "$root_dir" \
  --env-file "$tmp_dir/env" \
  -f "$root_dir/compose.yaml" \
  config --quiet

docker build --quiet --tag "$image" "$root_dir" >/dev/null
docker build --quiet --target vulncheck --tag "$scanner_image" "$root_dir" >/dev/null

test "$(docker image inspect --format '{{.Config.User}}' "$image")" = "1000:1000"
test "$(docker run --rm --entrypoint /bin/sh "$image" -c 'printf "%s:%s" "$(id -u)" "$(id -g)"')" = "1000:1000"
docker run --rm "$image" caddy list-modules | grep -qx 'dns.providers.cloudflare'
docker run --rm "$scanner_image"

for tls_mode in automatic dns01; do
  docker run --rm \
    --env ACME_EMAIL=admin@example.com \
    --env CF_API_TOKEN="$validation_token" \
    --env SITE_DOMAIN=service.example.com \
    --env TLS_MODE="$tls_mode" \
    --env UPSTREAM=app:8080 \
    --volume "$root_dir/config:/etc/caddy:ro" \
    "$image" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
done

if grep -RInE \
  --exclude='.env' \
  --exclude='validate.sh' \
  --exclude-dir='.git' \
  '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|CF_API_TOKEN=[^[:space:]]+|[[:alnum:]_.-]+\.(internal|local))' \
  "$root_dir"; then
  printf '%s\n' 'Potential private or secret value found.' >&2
  exit 1
fi

printf '%s\n' 'Validation passed.'
