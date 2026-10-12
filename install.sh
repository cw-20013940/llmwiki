#!/usr/bin/env bash
# install.sh — llmwiki 템플릿을 Obsidian 볼트에 설치하고 obsidian-save 스킬을 전역(~/.claude/skills)에 넣는다.
#
# 사용 (Git Bash):
#   bash install.sh "<볼트 절대경로>" ["<큐레이터 이름>"]
# 예:
#   bash install.sh "/c/Users/me/Documents/Obsidian Vault" "홍길동"
#
# 보장:
#   - 볼트의 기존 노트는 건드리지 않는다. 기존 CLAUDE.md 는 CLAUDE.md.before-llmwiki 로 이름만 바꿔 보존한다.
#   - 이미 설치된 볼트(AGENTS.md·index.md·log.md·scripts/ 중 하나라도 있음)면 아무것도 하지 않고 멈춘다.
#   - git init·원격 연결은 하지 않는다 (README 4단계에서 직접).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${1:-}"
CURATOR="${2:-사용자}"
[ -n "$VAULT" ] || { echo "usage: bash install.sh \"<볼트 절대경로>\" [\"<큐레이터 이름>\"]" >&2; exit 2; }
[ -d "$VAULT" ] || { echo "중단: 볼트 폴더가 없음 — $VAULT" >&2; exit 2; }
VAULT="$(cd "$VAULT" && pwd)"

for f in AGENTS.md index.md log.md scripts; do
  if [ -e "$VAULT/$f" ]; then
    echo "중단: $VAULT/$f 가 이미 있음 — 이미 설치됐거나 같은 이름의 파일이 있다. 직접 확인 후 진행하세요." >&2
    exit 1
  fi
done

# 1. 기존 CLAUDE.md 보존
if [ -f "$VAULT/CLAUDE.md" ]; then
  mv -- "$VAULT/CLAUDE.md" "$VAULT/CLAUDE.md.before-llmwiki"
  echo "보존: 기존 CLAUDE.md → CLAUDE.md.before-llmwiki (내용을 새 CLAUDE.md '이 볼트 전용 규칙'으로 옮긴 뒤 지워도 됨)"
fi

# 2. 템플릿 복사 (기존 파일 덮어쓰기 금지)
if [ -f "$VAULT/.gitignore" ]; then
  { printf '\n# ---- llmwiki 템플릿 (%s 추가) ----\n' "$(date +%F)"; cat "$HERE/template/.gitignore"; } >> "$VAULT/.gitignore"
  echo "병합: 기존 .gitignore 끝에 템플릿 규칙을 덧붙임"
fi
cp -rn "$HERE/template/." "$VAULT/"

# 3. CLAUDE.md 자리표시자 채우기 (sed 구분자·& 이스케이프)
esc() { printf '%s' "$1" | sed 's/[|&\\]/\\&/g'; }
NAME="$(basename "$VAULT")"
VAULT_W="$(cygpath -m "$VAULT" 2>/dev/null || printf '%s' "$VAULT")"   # C:/Users/... 형식 (Windows 도구 호환)
sed -i "s|{{VAULT_PATH}}|$(esc "$VAULT_W")|g; s|{{VAULT_NAME}}|$(esc "$NAME")|g; s|{{CURATOR}}|$(esc "$CURATOR")|g" "$VAULT/CLAUDE.md"

# 4. 전역 스킬 (기존 스킬은 백업)
SK="$HOME/.claude/skills/obsidian-save"
if [ -d "$SK" ]; then
  mkdir -p "$HOME/.claude/backups"
  BK="$HOME/.claude/backups/obsidian-save.bak-$(date +%Y%m%d-%H%M%S)"   # skills/ 밖에 둔다 — 안에 두면 백업본도 스킬로 읽힐 수 있음
  mv -- "$SK" "$BK"
  echo "백업: 기존 obsidian-save 스킬 → $BK"
fi
mkdir -p "$SK"
sed "s|{{VAULT_PATH}}|$(esc "$VAULT_W")|g" "$HERE/skills/obsidian-save/SKILL.md" > "$SK/SKILL.md"

echo ""
echo "설치 완료: $VAULT"
echo "다음 (README 참고):"
echo "  1) scripts/domains.txt 에 내 도메인, CLAUDE.md 도메인 표 맞추기"
echo "  2) 기존 업무 폴더가 있으면 scripts/raw-inplace-dirs.txt 에 폴더명"
echo "  3) 평문 키가 든 노트가 있으면 .gitignore 하단에 경로"
echo "  4) cd \"$VAULT\" && bash scripts/vault-lint.sh   → PASS 확인"
echo "  5) git init -b main && bash scripts/install-hooks.sh  (원격은 사내 저장소만)"
