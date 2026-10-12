# llmwiki — Obsidian LLM Wiki 템플릿 (사내 적응판)

Claude Code·Codex 같은 LLM 에이전트가 **사서**처럼 Obsidian 볼트를 정리·유지하게 만드는 템플릿과 규칙 모음이다.
원본 자료를 넣고 "이거 ingest해줘"라고 하면 요약·분류·교차링크·색인을 에이전트가 하고, 사람은 무엇을 넣을지와 무엇이 정본인지만 정한다.

> "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase." — Karpathy LLM Wiki 패턴

이 저장소에는 **템플릿과 규칙만** 있다. 각자의 업무 데이터(볼트)는 각자의 비공개 저장소에 둔다 — 이 저장소와 섞지 않는다.

## 들어 있는 것

| 경로 | 내용 |
|---|---|
| `template/` | 볼트에 복사되는 뼈대 — `CLAUDE.md`(규약)·`AGENTS.md`(작업 전 체크리스트)·`index.md`·`log.md`·`scripts/`·`AI-Sessions/` |
| `template/scripts/` | `vault-lint.sh`(정리 상태 점검) · `vault-append.sh`(기록 파일 안전 추가) · `vault-sync.sh`(git 동기화) · `hooks/pre-commit`(키 유출·구조 파손 커밋 차단) · `domain-card.sh` · `shelf-debt.py` |
| `skills/obsidian-save/` | Claude Code 전역 스킬 — "저장해 / ingest해줘"를 이 규약대로 처리 |
| `install.sh` | 볼트에 템플릿 설치 + 스킬 설치 |

## 3층 구조 한눈에

| 층 | 위치 | 누가 | 규칙 |
|---|---|---|---|
| 원본 (raw) | `AI-Sessions/raw/` (+ 기존 업무 폴더) | 사람 | 에이전트는 읽기만 |
| 위키 (wiki) | `AI-Sessions/wiki/` | 에이전트 | frontmatter·링크 필수, 원본 1:1 요약(sources) + 개념·절차·현황 페이지 |
| 규약 (schema) | `CLAUDE.md`·`AGENTS.md`·`index.md`·`log.md` | 함께 | 에이전트 행동의 정본 |

## 설치 (Windows, Git Bash)

준비물: [Obsidian](https://obsidian.md), Git for Windows(Git Bash 포함), Python 3, Claude Code.

```bash
git clone <사내 저장소 주소>/llmwiki.git
```

```bash
bash llmwiki/install.sh "/c/Users/<나>/Documents/Obsidian Vault" "<내 이름>"
```

- 볼트의 기존 노트는 건드리지 않는다. 기존 `CLAUDE.md`가 있으면 `CLAUDE.md.before-llmwiki`로 이름만 바꿔 보존한다.
- 이미 설치된 볼트면 아무것도 하지 않고 멈춘다.
- 기존 `~/.claude/skills/obsidian-save`가 있으면 `~/.claude/backups/obsidian-save.bak-<시각>`으로 백업한 뒤 새 스킬을 넣는다.

설치 후 볼트 폴더에서:

1. **도메인 정하기** — `scripts/domains.txt`에 내 분야 슬러그(영문 소문자)를 적고, `CLAUDE.md` 도메인 표와 `AI-Sessions/wiki/knowledge/<슬러그>/` 폴더를 맞춘다.
2. **기존 업무 폴더가 있으면** — 옮기지 말고 `scripts/raw-inplace-dirs.txt`에 폴더명을 적는다. 그 폴더는 원본(읽기 전용)으로 인정된다.
3. **평문 키가 든 노트가 있으면** — 값을 비밀관리 도구로 옮기고, 그 전까지는 `.gitignore` 하단에 경로를 적어 git에서 뺀다.
4. **점검** — `bash scripts/vault-lint.sh` → 맨 아래 `✅ vault-lint: PASS` 확인.
5. **git (선택, 여러 PC 동기화 시)** — `git init -b main` → `bash scripts/install-hooks.sh` → 원격은 **사내 저장소의 개인 비공개 저장소만** 연결. 첫 커밋 전 `git status`로 키 노트가 빠졌는지 확인.

## 사용법 (에이전트에게 이렇게 말한다)

| 말하기 | 일어나는 일 |
|---|---|
| "이거 저장해" | 방금 대화 결과를 위키 카테고리 1곳에 페이지로 저장 (있으면 갱신) |
| "이거 ingest해줘" | 원본 → `sources/` 1:1 요약 + 관련 페이지 여러 곳 갱신 |
| "X에 대해 뭐 있어?" | index·도메인 MOC에서 찾아 답하고 `[[출처]]` 표시 |
| "wiki 점검해줘" | `vault-lint.sh` 실행, 경고 정리 |

## lint 강도 — 완화판

`vault-lint.sh`는 볼트가 규칙대로 정리돼 있는지 자동 점검한다. 커밋할 때마다 돈다.

- **커밋을 막는 것(FAIL)**: 필수 구조 누락 · `log`/`index` 사본(동시 쓰기 충돌 흔적) · 원본 자동 수정 흔적 · **키 값 커밋(보안 — 완화하지 않음)**
- **알리기만 하는 것(경고)**: frontmatter 누락 · index 불일치 · 고립 페이지 · 파일명 규칙 · 루트 새 폴더

## 원본 템플릿과 다른 점

| 항목 | 변경 |
|---|---|
| lint | 위 완화판. 파일마다 검색하던 검사를 한 번에 훑도록 바꿔 Windows에서 약 2.5배 빠름 |
| 도메인 | 스크립트에 박혀 있던 목록을 `scripts/domains.txt` 한 곳에서 읽음 |
| 기존 볼트 | `scripts/raw-inplace-dirs.txt`로 기존 업무 폴더를 옮기지 않고 원본으로 인정 |
| 시크릿 패턴 | `feature_engineering` 같은 단어를 키로 오인하던 패턴 수정 |
| Windows | 스크립트 줄끝 LF 고정(`.gitattributes`), 경로 구분자 처리, `python` 호출, UTF-8 출력 |
| 보안·공유 | 원격은 사내 저장소만, 외부 공유(share-note 등) 전 사내 URL 제외 |

## 출처

원 구조는 Andrej Karpathy의 [LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)과, 이를 다중 에이전트 운영용으로 확장한 llm-wiki 템플릿(AI 강의 자료)을 바탕으로 사내 환경에 맞게 고친 것이다.
