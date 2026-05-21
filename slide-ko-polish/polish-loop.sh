#!/usr/bin/env bash
# slide-ko-polish-loop — Stage 4(LLM 어색함 검출) → 자동 수정 → 재검증 루프
# regex로 안 잡히는 어색한 표현만 반복적으로 검출·수정. PASS까지 또는 max iter까지.
#
# usage: polish-loop.sh <slide-file.html> [max_iter=5]

set -u
export LC_ALL=en_US.UTF-8

FILE="${1:-}"
MAX_ITER="${2:-5}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "usage: $0 <slide-file.html|.md> [max_iter=5]"
  exit 64
fi

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
VERIFY="$SKILL_DIR/verify.sh"

if [ -t 1 ]; then
  G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; B=$'\033[34m'; D=$'\033[2m'; N=$'\033[0m'
else
  G=; Y=; R=; B=; D=; N=
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "${R}claude CLI 필요. brew install claude 또는 npm i -g @anthropic-ai/claude-code${N}"
  exit 1
fi

for i in $(seq 1 "$MAX_ITER"); do
  echo
  echo "${B}╔═══ Iteration $i/$MAX_ITER ═══╗${N}"
  echo

  # 1. verify.sh 실행, Stage 4만 추출
  OUT=$("$VERIFY" "$FILE" 2>&1)

  # 2. Stage 4 결과 확인
  if echo "$OUT" | grep -q "Stage 4 PASS"; then
    echo "${G}✅ 수렴 — iteration $i 에서 Stage 4 PASS${N}"
    exit 0
  fi

  # 3. Stage 4 발견 사항만 추출
  FINDINGS=$(echo "$OUT" | awk '
    /\[Stage 4\]/ { in_s4=1; next }
    in_s4 && /━━━/ { exit }
    in_s4 && /^  - / { print }
    in_s4 && /^    /  { print }
  ')

  if [ -z "$FINDINGS" ]; then
    echo "${Y}Stage 4 발견사항 없음 — 종료${N}"
    exit 0
  fi

  echo "${D}─── LLM 발견 사항 ───${N}"
  echo "$FINDINGS"
  echo

  # 4. claude CLI에 수정 요청 (Edit 도구 허용)
  echo "${D}─── 자동 수정 적용 ───${N}"

  FIX_PROMPT="아래 한국어 슬라이드 HTML 파일에 어색한 표현이 발견되었습니다.
LLM 리뷰의 [수정안]을 적용해주세요.

[엄격한 원칙]
- 발견 사항의 [수정안]만 적용. 다른 곳 건드리지 말 것.
- 영어 약어/술어(verifier, AC, replay, fat-harness, ledger, run, auto, OS surface 등)는 의도적 용어. 보존.
- HTML 구조, class, id, style은 그대로.
- 슬라이드 의미·논리 보존.
- 각 수정 후 1줄로만 보고 (예: 'slide 4 note: 살아있는 → 존재').

[파일 경로]
$FILE

[LLM 리뷰 발견 사항]
$FINDINGS"

  echo "$FIX_PROMPT" | claude --print --effort medium \
    --allowed-tools "Edit Read Grep" \
    --add-dir "$(dirname "$FILE")" 2>&1 | tail -20

  echo
done

echo
echo "${R}╔═══ Max iterations ($MAX_ITER) 도달 — 수렴 실패 ═══╗${N}"
echo "${D}수동 검토 필요${N}"
exit 1
