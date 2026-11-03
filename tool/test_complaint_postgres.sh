#!/usr/bin/env bash
set -Eeuo pipefail

FRONT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACK_DIR="${QUALITY_BACKEND_DIR:-$FRONT_DIR/../Building-Manager-BackEnd}"

# A dedicated test database only; the suite creates and removes its own random schema.
# Never load .env.dev or reuse a development/production application's database.
if [[ -z "${COMPLAINT_TEST_DATABASE_URL:-}" ]]; then
  command -v psql >/dev/null || { echo 'FAIL: PostgreSQL 또는 COMPLAINT_TEST_DATABASE_URL 설정이 필요합니다.' >&2; exit 1; }
  command -v createdb >/dev/null || { echo 'FAIL: createdb 명령이 필요합니다.' >&2; exit 1; }
  psql -h 127.0.0.1 -p 5432 -d postgres -w -Atc 'SELECT 1' >/dev/null \
    || { echo 'FAIL: 로컬 PostgreSQL 연결을 확인하세요. 운영 DB는 사용할 수 없습니다.' >&2; exit 1; }
  if [[ "$(psql -h 127.0.0.1 -p 5432 -d postgres -w -Atc "SELECT 1 FROM pg_database WHERE datname='building-manager-test'")" != '1' ]]; then
    createdb -h 127.0.0.1 -p 5432 -w building-manager-test
  fi
  export COMPLAINT_TEST_DATABASE_URL="postgresql://$(id -un)@127.0.0.1:5432/building-manager-test"
fi

# The test validates host/database again before opening a connection. Do not print the URL.
cd "$BACK_DIR"
exec npm test -- --runInBand apps/api/src/modules/complaint-actions/complaint-actions.integration.spec.ts
