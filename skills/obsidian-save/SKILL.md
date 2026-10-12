---
name: obsidian-save
description: 사용자가 "옵시디언에 저장해줘", "vault에 저장", "save to obsidian", "이거 저장해", "이거 ingest해줘", "정리해줘(원본 반영)" 같은 자연어로 요청하면 발동. {{VAULT_PATH}} (LLM Wiki — Karpathy 패턴, llm-wiki 템플릿 적응판)에 볼트 CLAUDE.md·AGENTS.md 규약대로 save(대화 결과 → wiki 단일 페이지) 또는 ingest(원본 → sources 1:1 요약 + 관련 페이지 cross-update)를 수행하고, 루트 log.md에 vault-append.sh로 기록하며 vault-lint 통과를 확인한다.
triggers: ["옵시디언에 저장", "옵시디언 저장", "옵시디언에 보관", "옵시디언에 남겨", "vault에 저장", "vault 저장", "obsidian save", "save to obsidian", "save to vault", "이거 저장해", "이 답변 저장", "방금 답변 저장", "wiki에 저장", "작업내용 저장", "ingest", "인제스트", "원본 반영", "위키에 반영"]
---

# obsidian-save

대화 결과나 원본 자료를 사용자의 Obsidian 볼트(LLM Wiki)에 넣는다. **볼트의 `CLAUDE.md`·`AGENTS.md`가 정본이다** — 이 스킬과 어긋나면 볼트 규약을 따른다.

## 대상 볼트 (고정)

`{{VAULT_PATH}}` — 다른 경로(예전 볼트, `.archive-*`, 백업 폴더)에는 쓰지 않는다.

```
CLAUDE.md · AGENTS.md · index.md · log.md       ← 스키마 (먼저 읽는다)
scripts/                                         ← vault-lint · vault-append · vault-sync · 훅
<기존 업무 폴더들>/                              ← scripts/raw-inplace-dirs.txt 에 적힌 제자리 원본(raw). 읽기 전용
                                                 (폴더별 예외 권한은 CLAUDE.md "이 볼트 전용 규칙")
AI-Sessions/
├── raw/ articles·papers·notes·inbox·assets     ← 새 외부 자료 (불변)
├── conversations/<프로젝트>/                     ← 핸드오버 원장 (불변)
├── _templates/                                  ← Templater 템플릿
└── wiki/ sources·concepts·decisions·playbooks·projects·entities·errors·synthesis·knowledge·_status
```

## 절차

### 0. 사전점검 (매번, AGENTS.md 0번 체크리스트)
1. 볼트 `CLAUDE.md`(특히 "이 볼트 전용 규칙")·`AGENTS.md`를 읽는다. 기억에 의존하지 않는다.
2. `index.md`에서 해당 카테고리 섹션, `AI-Sessions/wiki/_status/contested.md`, `active.md`를 확인한다. contested 주제는 정본처럼 쓰지 않는다.
3. 볼트 루트에서 `bash scripts/vault-sync.sh pull` (원격 없으면 자동 생략) → `bash scripts/vault-lint.sh --quiet; echo $?` — **exit 0이 아니면 신규 쓰기 금지**, 실패 항목을 사용자에게 보고하고 멈춘다.
4. `date "+%F %H:%M"`으로 날짜·시각 확인 (추측 금지).

### 1. save / ingest 구분
| 요청 | 종류 | 결과 |
|---|---|---|
| "이거 저장해", "이 답변 저장", "작업내용 저장" | **save** | 대화의 합성 결과 → wiki 카테고리 1개에 단일 페이지 (기존 페이지가 있으면 갱신) |
| "이거 ingest해줘", "원본 반영", raw/·제자리 원본의 특정 파일 지목 | **ingest** | `wiki/sources/` 1:1 요약 + 관련 페이지 cross-update |
| 외부 아티클·논문·영상 링크/본문을 저장하라고 함 | **ingest로 우회** | 먼저 `AI-Sessions/raw/<종류>/`에 원문을 두고(사용자 확인) ingest |

### 2. save
- 카테고리: 프로젝트 상태→`projects/`(프로젝트명만, 날짜·session 접미사 금지) · 오류→`errors/` · 절차→`playbooks/` · 결정→`decisions/YYYY-MM-DD-slug.md` · 비교·지도→`synthesis/` · 이론→`concepts/` · 도구·조직→`entities/`.
- 같은 주제 페이지가 있으면 새로 만들지 말고 갱신 (`grep -rl "<키워드>" AI-Sessions/wiki`).
- frontmatter는 볼트 `CLAUDE.md` 표준(type·title·summary·status·created·updated·verified·source_of_truth·contested·author·related·tags·sources). `tags`에 `domain/<scripts/domains.txt 의 슬러그>` 1개, `author: agent`.
- 본문 첫 줄(H1 다음) `> 한 문장 요약`, 최소 1개 `[[link]]` — 소속 도메인 MOC(`[[<domain>-moc]]`)를 `related`에 넣으면 orphan이 안 된다.
- 원본 폴더에 새 노트를 쓰지 않는다. 대화 결과는 언제나 wiki 로 (예외는 볼트 CLAUDE.md "이 볼트 전용 규칙"에 적힌 것만).

### 3. ingest
1. 원본을 읽기만 한다 (수정·삭제·이동 금지).
2. `AI-Sessions/wiki/sources/YYYY-MM-DD-<type>-<kebab-slug>.md` 생성 — `AI-Sessions/_templates/source.md` 형식, `raw_path:`에 볼트 기준 원본 경로, `verified:`에 오늘.
3. 영향 받는 기존 페이지 cross-update (목표 10~15, 1~2개면 save였을 가능성 재검토). 기존 주장과 모순이면 `> [!warning] 모순:` + `_status/contested.md`에 Unresolved 행 (`vault-append.sh` 사용) + 해당 페이지 `contested: true`.
4. 도메인 MOC의 "ingest 대기 원본" 목록에서 해당 줄을 새 source 링크로 바꾼다 (source orphan 방지 — lint 12번이 FAIL로 막음).
5. 평문 키가 든 원본(`.gitignore`에 등재된 파일)은 요약에도 값을 옮기지 않는다 — 환경변수 이름·저장 위치만.

### 4. 기록 · 검증 · 보고
1. `index.md` 해당 카테고리 섹션에 `- [[페이지]] — 한 줄 요약 (status)` **부분 편집** (하단 append 금지).
2. log: `bash scripts/vault-append.sh log.md "## [YYYY-MM-DD HH:MM] save|ingest | <대상> @[claude]` + 줄바꿈 + `- 무엇을 했는지 1~3줄"`. 이 기록이 주간보고 소스가 된다.
3. `bash scripts/vault-lint.sh --quiet; echo $?` → 0 확인. 실패면 고치고 재실행.
4. 커밋: 자기가 만든/고친 파일만 명시 — `bash scripts/vault-sync.sh push "docs: <요약>" <파일...>` (`git add .`/`-A` 금지, 시크릿 게이트 자동).
5. 보고 (AGENTS.md 형식): 변경 파일 · 카테고리 근거 · lint 결과 · index/log 갱신 · 후속 권장.

## 절대 금지
- 제자리 원본·`AI-Sessions/raw`·`conversations` 수정/삭제/이동
- lint FAIL 상태에서 신규 쓰기 / log·index·active·contested 통째 덮어쓰기
- 원본에 없는 수치·데이터 만들기 (모르면 `미확인`, 모순이면 둘 다 + contested)
- 계정정보·API 키·토큰·비밀번호·개인정보 기록 (사내 도메인 이름은 허용, 외부 공유 페이지에서는 사내 URL 제외)
- 사외 원격(외부 GitHub 등)으로 push — 원격은 사내 저장소만
