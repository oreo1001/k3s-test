#!/bin/bash
# ============================================================
# terraform apply 자동 재시도 스크립트
# Out of host capacity 에러 시 대기 후 재시도
# 사용법: bash scripts/terraform_apply_retry.sh
# ============================================================

WAIT_SECONDS=120     # 재시도 간격 (초)
TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"

echo "============================="
echo " terraform apply 자동 재시도"
echo " 성공할 때까지 ${WAIT_SECONDS}초 간격으로 반복"
echo " 중단: Ctrl+C"
echo "============================="

cd "$TF_DIR"

i=1
while true; do
  echo ""
  echo "[$(date '+%H:%M:%S')] 시도 ${i}회차..."

  TMPFILE=$(mktemp)
  terraform apply -auto-approve 2>&1 | tee "$TMPFILE"
  EXIT_CODE=${PIPESTATUS[0]}
  OUTPUT=$(cat "$TMPFILE")
  rm -f "$TMPFILE"

  if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✓ terraform apply 성공!"
    exit 0
  fi

  if echo "$OUTPUT" | grep -qi "out of host capacity"; then
    echo ""
    echo "→ Out of host capacity. ${WAIT_SECONDS}초 후 재시도... (Ctrl+C로 중단)"
    sleep $WAIT_SECONDS
  else
    echo ""
    echo "✗ 다른 에러 발생. 재시도 중단."
    exit 1
  fi

  i=$((i + 1))
done
