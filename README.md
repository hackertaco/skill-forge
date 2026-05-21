# skill-forge

내가 만들고 다듬는 AI CLI 스킬 모음. 대장간(forge)에서 망치질하듯 깎아낸 스킬들을 모아두는 레포.

**Claude Code, OpenAI Codex, Gemini CLI 모두에서 동작.** 스킬은 bash 기반이라 어떤 환경에서도 호출 가능하고, Stage 4(LLM 검토)는 `claude` / `codex` / `gemini` 중 설치된 CLI를 자동 감지해서 호출합니다.

## Quickstart — 다른 사람이 쓰는 법

```bash
# 1. 클론
git clone https://github.com/hackertaco/skill-forge.git
cd skill-forge

# 2. 검증 실행 (LLM CLI 자동 감지: claude → codex → gemini 순)
./slide-ko-polish/verify.sh path/to/slide.html

# 3. LLM CLI 강제 지정 (override)
LLM_CLI=claude  ./slide-ko-polish/verify.sh path/to/slide.html
LLM_CLI=codex   ./slide-ko-polish/verify.sh path/to/slide.html
LLM_CLI=gemini  ./slide-ko-polish/verify.sh path/to/slide.html

# 4. PASS까지 자동 루프 (max 5회)
./slide-ko-polish/polish-loop.sh path/to/slide.html
```

`path/to/slide.html` 자리는 본인 슬라이드 파일 상대 경로. 절대경로도 됨.

### (옵션) Claude Code에서 슬래시 명령으로 호출하려면 심볼릭 링크

위 Quickstart는 어떤 환경이든 동작합니다. Claude Code에서 트리거 키워드("발표자료 다듬어")나 `/slide-ko-polish` 명령으로 호출하고 싶으면 심볼릭 링크 추가:

```bash
# 레포 폴더 안에서
ln -s "$(pwd)/slide-ko-polish" ~/.claude/skills/slide-ko-polish    # Claude Code
ln -s "$(pwd)/slide-ko-polish" ~/.agents/skills/slide-ko-polish    # Codex
```

## 지원 환경

| 환경 | 동작 |
|---|---|
| **Claude Code** | 트리거 키워드("발표자료 다듬어" 등) 또는 `/slide-ko-polish` 슬래시 명령으로 호출. SKILL.md 자동 로드. |
| **OpenAI Codex CLI** | `~/skill-forge/slide-ko-polish/verify.sh slide.html` 직접 호출. Stage 4가 `codex exec` 사용. |
| **Gemini CLI** | 동일하게 직접 호출. Stage 4가 `gemini --non-interactive` 사용. |
| **모든 환경** (LLM CLI 없어도) | Stage 1·1.5(regex/구조 검증)는 LLM 없이 동작. Stage 4만 건너뜀. |

## 설치 방법

### 전체 설치 (모든 스킬을 `~/.claude/skills/` 또는 `~/.agents/skills/` 에 심볼릭 링크)

```bash
git clone https://github.com/hackertaco/skill-forge.git ~/skill-forge

# Claude Code 유저
for skill in ~/skill-forge/*/; do
  name=$(basename "$skill")
  [ ! -L "$HOME/.claude/skills/$name" ] && ln -s "$skill" "$HOME/.claude/skills/$name"
done

# Codex 유저
for skill in ~/skill-forge/*/; do
  name=$(basename "$skill")
  [ ! -L "$HOME/.agents/skills/$name" ] && ln -s "$skill" "$HOME/.agents/skills/$name"
done
```

### 개별 스킬만 설치

```bash
git clone https://github.com/hackertaco/skill-forge.git ~/skill-forge
ln -s ~/skill-forge/slide-ko-polish ~/.claude/skills/slide-ko-polish    # Claude
# 또는
ln -s ~/skill-forge/slide-ko-polish ~/.agents/skills/slide-ko-polish    # Codex
```

### 심볼릭 링크 없이 직접 호출

bash 스크립트라 어디서든 실행 가능:

```bash
~/skill-forge/slide-ko-polish/verify.sh slide.html
```

## 수록 스킬

### [slide-ko-polish](./slide-ko-polish/)

영어 → 한국어로 번역된 발표 슬라이드를 자연스러운 한국어로 다듬는다.

**4단계 검증:**

| Stage | 검사 내용 | 자동/수동 |
|---|---|---|
| 1 | 번역체 11시그널 regex 스캔 (`~기 전에`, `~을 통해`, `그것` 등) | 자동 |
| 1.5 | HTML 구조 (CSS, max-width) + 조사·수식어 + `<br />` 분리 패턴 | 자동 |
| 2 | 브라우저 스크린샷 명령어 출력 | 수동 (눈) |
| 3 | 입말 테스트 안내 | 수동 (입) |
| 4 | LLM Fresh Review — regex로 못 잡는 어색함, 영어 직역 은유, 제목↔본문 호응 | 자동 (CLI 감지) |

**기본 사용:**

```bash
# 한 번 검증
~/skill-forge/slide-ko-polish/verify.sh slide.html

# PASS 까지 자동 루프 (max 5회) — Stage 4 발견 사항을 LLM이 자동 수정
~/skill-forge/slide-ko-polish/polish-loop.sh slide.html
```

**LLM CLI 명시:**

```bash
# 자동 감지 (claude → codex → gemini 순)
verify.sh slide.html

# 명시적 지정
LLM_CLI=claude verify.sh slide.html
LLM_CLI=codex  verify.sh slide.html
LLM_CLI=gemini verify.sh slide.html
```

**요구사항:**

- LLM CLI 중 하나 (Stage 4용)
  - `claude` — [Anthropic Claude Code](https://claude.com/claude-code)
  - `codex` — [OpenAI Codex CLI](https://github.com/openai/codex)
  - `gemini` — [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)
- `perl` (텍스트 추출, macOS·Linux 기본 탑재)
- `agent-browser` (옵션, Stage 2 시각 검증용)

## 아키텍처

```
사용자 호출
   │
   ▼
verify.sh ──► Stage 1   regex 번역체 11시그널
   │     ──► Stage 1.5 HTML 구조 + <br /> 분리 패턴
   │     ──► Stage 2   스크린샷 명령어 안내
   │     ──► Stage 3   입말 테스트 안내
   │     ──► Stage 4   ┌─ claude --print --effort low      (감지: claude 우선)
   │                   ├─ codex exec --skip-git-repo-check (codex 차순위)
   │                   └─ gemini --non-interactive         (gemini 최종)
   ▼
PASS / WARN / FAIL
```

`polish-loop.sh` 는 verify.sh를 반복 실행하며 Stage 4 발견 사항을 LLM이 자동 수정 → Stage 4 PASS 되면 종료. 최대 반복 횟수는 인자로 조정 가능.

## 새 스킬 추가하기

```bash
cd ~/skill-forge
mkdir my-new-skill
# SKILL.md (frontmatter: name, description) + 스크립트 작성
git add my-new-skill && git commit -m "feat: my-new-skill 추가" && git push
```

심볼릭 링크가 이미 걸려있으면 `~/.claude/skills/` 에 자동 등록됨.

## 라이선스

MIT
