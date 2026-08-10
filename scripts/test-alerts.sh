#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENVIRONMENT="${ENVIRONMENT:-development}"
CONTAINER_NAME_PREFIX="${CONTAINER_NAME_PREFIX:-terraform-docker-lab}"
NETWORK_NAME="${NETWORK_NAME:-${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-network}"
API_CONTAINER="${API_CONTAINER:-${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-api}"
NGINX_CONTAINER="${NGINX_CONTAINER:-${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-nginx}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://127.0.0.1:9093}"
MAILPIT_URL="${MAILPIT_URL:-http://127.0.0.1:8025}"
APPLICATION_URL="${APPLICATION_URL:-http://127.0.0.1:8081}"
K6_IMAGE="${K6_IMAGE:-grafana/k6:2.1.0@sha256:65c920dc067d5e2e00befbf982af6ad6ad0117034e8b1c65817c7975c52d4669}"
ALERT_TIMEOUT_SECONDS="${ALERT_TIMEOUT_SECONDS:-360}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-5}"
K6_PID=""
K6_LOG=""
API_STOPPED=0

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Gerekli araç bulunamadı: $1"
}

deadline() {
  date +%s
}

poll_until() {
  local description="$1"
  local command="$2"
  local end=$(( $(deadline) + ALERT_TIMEOUT_SECONDS ))
  while (( $(deadline) < end )); do
    if eval "$command"; then
      echo "OK: $description"
      return 0
    fi
    sleep "$POLL_INTERVAL_SECONDS"
  done
  echo "ERROR: zaman aşımı: $description" >&2
  show_status
  return 1
}

container_healthy() {
  local container="$1"
  [[ "$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" == "running" ]] &&
    [[ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$container" 2>/dev/null)" =~ ^(healthy|no-healthcheck)$ ]]
}

check_services() {
  local container
  for container in "$API_CONTAINER" "$NGINX_CONTAINER" \
    "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-prometheus" \
    "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-alertmanager" \
    "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-mailpit"; do
    container_healthy "$container" || return 1
  done
  curl -fsS "$APPLICATION_URL/health" >/dev/null &&
    curl -fsS "$PROMETHEUS_URL/-/ready" >/dev/null &&
    curl -fsS "$ALERTMANAGER_URL/-/ready" >/dev/null &&
    curl -fsS "$MAILPIT_URL/api/v1/messages?limit=1" >/dev/null
}

container_has_alias() {
  local alias="$1"
  local container="$2"
  docker inspect "$container" |
    jq -e --arg network "$NETWORK_NAME" --arg alias "$alias" '.[0].NetworkSettings.Networks[$network].Aliases | index($alias) != null' >/dev/null
}

show_status() {
  echo "--- container status ---" >&2
  docker ps --filter "name=${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-" \
    --format '{{.Names}}\t{{.Status}}' >&2 || true
  echo "--- Prometheus alerts ---" >&2
  curl -fsS "$PROMETHEUS_URL/api/v1/alerts" 2>/dev/null | jq . >&2 || true
  echo "--- Alertmanager alerts ---" >&2
  curl -fsS "$ALERTMANAGER_URL/api/v2/alerts" 2>/dev/null | jq . >&2 || true
}

prometheus_state() {
  local alert="$1"
  curl -fsS "$PROMETHEUS_URL/api/v1/alerts" |
    jq -r --arg alert "$alert" '[.data.alerts[]? | select(.labels.alertname == $alert) | .state] | if length == 0 then "absent" else .[0] end'
}

alert_state_is() {
  [[ "$(prometheus_state "$1")" == "$2" ]]
}

alertmanager_has_alert() {
  local alert="$1"
  curl -fsS "$ALERTMANAGER_URL/api/v2/alerts" |
    jq -e --arg alert "$alert" 'any(.[]?; .labels.alertname == $alert)' >/dev/null
}

mailpit_has_alert() {
  local alert="$1"
  local messages
  messages="$(curl -fsS "$MAILPIT_URL/api/v1/messages?limit=100")"
  jq -e --arg alert "$alert" 'any(.. | strings; contains($alert))' <<<"$messages" >/dev/null
}

run_k6() {
  local scenario="$1"
  K6_LOG="$(mktemp "${TMPDIR:-/tmp}/k6-alert.XXXXXX.log")"
  echo "k6 senaryosu çalışıyor: $scenario (log: $K6_LOG)"
  docker run --rm --network "$NETWORK_NAME" \
    -v "$REPO_ROOT/k6:/scripts:ro" \
    -e K6_BASE_URL="http://${NGINX_CONTAINER}:80" \
    "$K6_IMAGE" run "/scripts/$scenario.js" >"$K6_LOG" 2>&1 &
  K6_PID=$!
}

wait_k6() {
  local result=0
  wait "$K6_PID" || result=$?
  K6_PID=""
  tail -n 30 "$K6_LOG" || true
  rm -f "$K6_LOG"
  return "$result"
}

mailpit_baseline() {
  curl -fsS "$MAILPIT_URL/api/v1/messages?limit=100" |
    jq -r '.messages[]? | (.ID // .id // empty)' | sort
}

run_alert_scenario() {
  local scenario="$1"
  local alert="$2"
  local summary="$3"
  local baseline="$4"
  echo "Alarm testi: $alert"
  poll_until "$alert yok" "! alert_state_is '$alert' firing"
  run_k6 "$scenario"
  poll_until "$alert pending" "alert_state_is '$alert' pending"
  poll_until "$alert firing" "alert_state_is '$alert' firing"
  poll_until "$alert Alertmanager'a ulaştı" "alertmanager_has_alert '$alert'"
  poll_until "$alert Mailpit'e ulaştı" "mailpit_has_alert '$alert'"
  wait_k6 || die "k6 $scenario başarısız oldu"
  poll_until "$alert resolved" "alert_state_is '$alert' absent"
  echo "OK: $alert pending -> firing -> resolved; bildirim gözlendi (baseline: $baseline, summary: $summary)"
}

cleanup() {
  local result=$?
  if [[ -n "$K6_PID" ]]; then
    kill "$K6_PID" 2>/dev/null || true
    wait "$K6_PID" 2>/dev/null || true
  fi
  if (( API_STOPPED )); then
    docker start "$API_CONTAINER" >/dev/null 2>&1 || true
    poll_until "API yeniden healthy" "container_healthy '$API_CONTAINER'" || true
  fi
  if ! check_services; then
    echo "ERROR: cleanup sonrası servis health kontrolü başarısız." >&2
    show_status
    result=1
  fi
  exit "$result"
}
trap cleanup EXIT INT TERM

main() {
  require_command docker
  require_command curl
  require_command jq
  docker info >/dev/null 2>&1 || die "Docker daemon erişilebilir değil."
  docker network inspect "$NETWORK_NAME" >/dev/null 2>&1 || die "Network bulunamadı: $NETWORK_NAME"
  container_has_alias api "$API_CONTAINER" || die "API container'ında 'api' alias'ı bulunamadı: $NETWORK_NAME"
  container_has_alias prometheus "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-prometheus" || die "Prometheus container'ında alias bulunamadı: $NETWORK_NAME"
  container_has_alias alertmanager "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-alertmanager" || die "Alertmanager container'ında alias bulunamadı: $NETWORK_NAME"
  container_has_alias mailpit "${CONTAINER_NAME_PREFIX}-${ENVIRONMENT}-mailpit" || die "Mailpit container'ında alias bulunamadı: $NETWORK_NAME"
  check_services || die "Başlangıç servis health kontrolü başarısız."
  test_error_status="$(curl -sS -o /dev/null -w '%{http_code}' "$APPLICATION_URL/_test/error")"
  [[ "$test_error_status" == "500" ]] ||
    die "Kontrollü test endpoint'i etkin değil: /_test/error HTTP $test_error_status (enable_test_endpoints=true gerekir)."
  local mode="${1:-all}"
  local baseline
  baseline="$(mailpit_baseline)"
  case "$mode" in
    error) run_alert_scenario error HighErrorRate "high error rate" "$baseline" ;;
    latency) run_alert_scenario latency HighP95Latency "high p95 latency" "$baseline" ;;
    down)
      echo "Alarm testi: FastAPIDown"
      poll_until "FastAPIDown yok" "! alert_state_is FastAPIDown firing"
      docker stop "$API_CONTAINER" >/dev/null
      API_STOPPED=1
      run_k6 down
      poll_until "FastAPIDown pending" "alert_state_is FastAPIDown pending"
      poll_until "FastAPIDown firing" "alert_state_is FastAPIDown firing"
      poll_until "FastAPIDown Alertmanager'a ulaştı" "alertmanager_has_alert FastAPIDown"
      poll_until "FastAPIDown Mailpit'e ulaştı" "mailpit_has_alert FastAPIDown"
      wait_k6 || die "k6 down başarısız oldu"
      docker start "$API_CONTAINER" >/dev/null
      API_STOPPED=0
      poll_until "API yeniden healthy" "container_healthy '$API_CONTAINER'"
      poll_until "FastAPIDown resolved" "alert_state_is FastAPIDown absent"
      ;;
    all)
      run_alert_scenario error HighErrorRate "high error rate" "$baseline"
      run_alert_scenario latency HighP95Latency "high p95 latency" "$baseline"
      "$0" down
      ;;
    *) die "Kullanım: $0 [error|latency|down|all]" ;;
  esac
}

main "$@"
