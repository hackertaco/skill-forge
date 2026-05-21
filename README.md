# skill-forge

내가 만들고 다듬는 Claude Code 스킬 모음. 대장간(forge)에서 망치질하듯 깎아낸 스킬들을 모아두는 레포.

## 설치 방법

각 스킬은 독립적으로 동작합니다. 원하는 스킬만 골라서 `~/.claude/skills/` 에 심볼릭 링크로 연결하세요.

### 전체 설치

```bash
git clone https://github.com/hackertaco/skill-forge.git ~/skill-forge
for skill in ~/skill-forge/*/; do
  name=$(basename "$skill")
  [ -d "$name" ] && [ ! -L "$HOME/.claude/skills/$name" ] && \
    ln -s "$skill" "$HOME/.claude/skills/$name"
done
```

### 개별 스킬만 설치

```bash
git clone https://github.com/hackertaco/skill-forge.git ~/skill-forge
ln -s ~/skill-forge/slide-ko-polish ~/.claude/skills/slide-ko-polish
```

## 수록 스킬

### [slide-ko-polish](./slide-ko-polish/)

영어 → 한국어로 번역된 발표 슬라이드를 자연스러운 한국어로 다듬는다.

- **Stage 1** 번역체 11시그널 regex 스캔
- **Stage 1.5** HTML 구조 + 조사·수식어 + `<br />` 패턴 검사
- **Stage 2** 브라우저 스크린샷 안내
- **Stage 3** 입말 테스트 안내
- **Stage 4** Claude CLI로 LLM Fresh Review — regex로 못 잡는 어색함 검출

`polish-loop.sh` 로 PASS까지 자동 반복 가능.

```bash
# 한 번 검증
~/.claude/skills/slide-ko-polish/verify.sh slide.html

# PASS 까지 자동 루프 (max 5회)
~/.claude/skills/slide-ko-polish/polish-loop.sh slide.html
```

**요구사항:**
- LLM CLI 중 하나 (Stage 4 — 자동 LLM 검토)
  - `claude` (Anthropic Claude Code) — 기본
  - `codex` (OpenAI Codex) — 자동 fallback
  - `gemini` (Google Gemini CLI) — 자동 fallback
  - 수동 지정: `LLM_CLI=codex verify.sh slide.html`
- `agent-browser` (Stage 2 — 시각 검증, 옵션)
- `perl` (텍스트 추출, macOS·Linux 기본 탑재)

**Claude Code 외부 환경에서도 사용 가능** — bash 스크립트가 CLI 자동 감지해서 어떤 LLM이든 동작.

## 라이선스

MIT
