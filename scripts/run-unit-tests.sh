#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIRECTORY="${ROOT}/build/unit-test-results"
RESULT_LOG="${RESULT_DIRECTORY}/fitness-core-tests-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "${RESULT_DIRECTORY}"
cd "${ROOT}"
{
  echo "Running FitnessCore unit tests"
  swift test --package-path FitnessCore
} 2>&1 | tee "${RESULT_LOG}"
echo "Unit-test result: ${RESULT_LOG}"
