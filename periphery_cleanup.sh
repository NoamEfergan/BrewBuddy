#!/usr/bin/env bash

# Periphery Cleanup Script
# Robust, safe, portable helper to detect and neutralize unused Swift code.
# - Installs Periphery if missing (via Homebrew if available)
# - Ensures a .periphery.yml exists (auto-generates one for Xcode projects)
# - Runs scan, annotates unused symbols (@available(*, deprecated, ...))
# - Suggests whole-file removals when safe to do so
# - Re-runs scan once to confirm improvements, avoids loops

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# CLI arguments
AUTO_MODE=0
OVERRIDE_SCHEME=""
OVERRIDE_TARGET=""
OVERRIDE_WORKSPACE=""
OVERRIDE_PROJECT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -a, --auto              Generate .periphery.yml non-interactively (no prompts)
  -s, --scheme NAME       Scheme to use when generating config (auto mode)
  -t, --target NAME       Target to use when generating config (auto mode)
  -w, --workspace PATH    Use this .xcworkspace (auto mode)
  -p, --project PATH      Use this .xcodeproj (auto mode)
  -h, --help              Show this help

Defaults:
  - Without --auto, the script launches Periphery's guided setup (interactive)
  - With --auto, the script detects workspace/project & picks a scheme/target
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--auto) AUTO_MODE=1; shift ;;
    -s|--scheme) OVERRIDE_SCHEME="$2"; shift 2 ;;
    -t|--target) OVERRIDE_TARGET="$2"; shift 2 ;;
    -w|--workspace) OVERRIDE_WORKSPACE="$2"; shift 2 ;;
    -p|--project) OVERRIDE_PROJECT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Determine project root robustly
determine_root() {
  local dir
  # Prefer git root if available
  if command -v git >/dev/null 2>&1; then
    local git_root
    git_root=$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$git_root" && -d "$git_root" ]]; then
      echo "$git_root"
      return
    fi
  fi
  # Walk up until we find an Xcode project/workspace
  dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" && -n "$dir" ]]; do
    if compgen -G "$dir/*.xcworkspace" > /dev/null || compgen -G "$dir/*.xcodeproj" > /dev/null; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  # Fallback: parent of tools
  echo "$(cd "$SCRIPT_DIR/.." && pwd)"
}

ROOT_DIR="$(determine_root)"
cd "$ROOT_DIR"

ASCII_LOGO="
============================================================
   _____                 _                 _
  |  __ \               (_)               | |
  | |__) |___ _ __ _ __  _ _ __ _   _  ___| |_ ___ _ __
  |  _  // _ \ '__| '_ \| | '__| | | |/ __| __/ _ \ '__|
  | | \ \  __/ |  | |_) | | |  | |_| | (__| ||  __/ |
  |_|  \_\___|_|  | .__/|_|_|   \__,_|\___|\__\___|_|
                   | |
                   |_|   Cleanup • Periphery Automation
============================================================
"

info()  { printf "\033[1;34m[INFO]\033[0m %s\n"  "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n"  "$*"; }
err()   { printf "\033[1;31m[ERR ]\033[0m %s\n"  "$*"; }
good()  { printf "\033[1;32m[DONE]\033[0m %s\n"  "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

echo "$ASCII_LOGO"

# 1) Ensure periphery is installed
if ! command -v periphery >/dev/null 2>&1; then
  warn "Periphery not found. Attempting install via Homebrew."
  if command -v brew >/dev/null 2>&1; then
    info "brew install periphery"
    brew install periphery || {
      err "Failed to install Periphery via Homebrew. Please install Periphery manually and re-run."
      exit 1
    }
    good "Periphery installed."
  else
    err "Homebrew not found. Please install Homebrew (https://brew.sh) or Periphery manually, then rerun."
    exit 1
  fi
else
  good "Periphery found: $(command -v periphery)"
fi

detect_targets_from_list() {
  # Reads xcodebuild -list output from stdin, prints Targets as lines
  awk '/Targets:/{flag=1;next} flag && NF {print $0} /^\s*$/{if(flag) exit}' \
    | sed 's/^ *//;s/ *$//' | sed '/^$/d'
}

append_targets_to_config() {
  local cfg="$1"; shift
  local targets=("$@")
  [[ ${#targets[@]} -eq 0 ]] && return 0
  if ! grep -q '^targets:' "$cfg" 2>/dev/null; then
    info "Adding targets to $cfg: ${targets[*]}"
    {
      echo "targets:"
      for t in "${targets[@]}"; do echo "  - $t"; done
    } >> "$cfg"
  fi
}

# 2) Ensure .periphery.yml exists
CONFIG_FILE="$ROOT_DIR/.periphery.yml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  if [[ "$AUTO_MODE" -eq 1 ]]; then
    warn ".periphery.yml not found. Generating a non-interactive configuration (auto mode)..."

    # Resolve workspace/project
    if [[ -n "$OVERRIDE_WORKSPACE" ]]; then
      WORKSPACE_CANDIDATE="$OVERRIDE_WORKSPACE"
    else
      WORKSPACE_CANDIDATE=$(find "$ROOT_DIR" -maxdepth 1 -name "*.xcworkspace" -print -quit || true)
    fi
    if [[ -n "$OVERRIDE_PROJECT" ]]; then
      PROJECT_CANDIDATE="$OVERRIDE_PROJECT"
    else
      PROJECT_CANDIDATE=$(find "$ROOT_DIR" -maxdepth 1 -name "*.xcodeproj" -print -quit || true)
    fi

    if [[ -n "$WORKSPACE_CANDIDATE" ]]; then
      info "Using workspace: $(basename "$WORKSPACE_CANDIDATE")"
      LIST_OUTPUT=$(xcodebuild -list -workspace "$WORKSPACE_CANDIDATE" 2>/dev/null || true)
    elif [[ -n "$PROJECT_CANDIDATE" ]]; then
      info "Using project: $(basename "$PROJECT_CANDIDATE")"
      LIST_OUTPUT=$(xcodebuild -list -project "$PROJECT_CANDIDATE" 2>/dev/null || true)
    else
      err "No .xcworkspace or .xcodeproj found at $ROOT_DIR. Cannot configure Periphery."
      exit 1
    fi

    # Extract schemes and targets (compatible with bash 3.2 on macOS)
    SCHEMES=()
    TARGETS=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && SCHEMES+=("$line")
    done <<EOF
$(printf "%s\n" "$LIST_OUTPUT" | awk '/Schemes:/{flag=1;next} flag && NF {print $0} /^\s*$/{if(flag) exit}' | sed 's/^ *//;s/ *$//')
EOF
    while IFS= read -r line; do
      [[ -n "$line" ]] && TARGETS+=("$line")
    done <<EOF
$(printf "%s\n" "$LIST_OUTPUT" | awk '/Targets:/{flag=1;next} flag && NF {print $0} /^\s*$/{if(flag) exit}' | sed 's/^ *//;s/ *$//')
EOF

    DEFAULT_SCHEME="${OVERRIDE_SCHEME:-${SCHEMES[0]:-}}"
    DEFAULT_TARGET="${OVERRIDE_TARGET:-${TARGETS[0]:-}}"

    # Prefer a scheme/target named BrewBuddy if present and not overridden
    if [[ -z "$OVERRIDE_SCHEME" ]]; then
      for s in "${SCHEMES[@]}"; do
        if [[ "$s" == "BrewBuddy" ]]; then DEFAULT_SCHEME="$s"; break; fi
      done
    fi
    if [[ -z "$OVERRIDE_TARGET" ]]; then
      for t in "${TARGETS[@]}"; do
        if [[ "$t" == "BrewBuddy" ]]; then DEFAULT_TARGET="$t"; break; fi
      done
    fi

    if [[ -z "$DEFAULT_SCHEME" || -z "$DEFAULT_TARGET" ]]; then
      err "Failed to detect a scheme/target from xcodebuild. Use --scheme/--target or ensure the project builds."
      exit 1
    fi

    {
      if [[ -n "$WORKSPACE_CANDIDATE" ]]; then
        echo "workspace: $(basename "$WORKSPACE_CANDIDATE")"
      else
        echo "project: $(basename "$PROJECT_CANDIDATE")"
      fi
      echo "schemes:"
      echo "  - $DEFAULT_SCHEME"
      echo "targets:"
      echo "  - $DEFAULT_TARGET"
      echo "retain_public: false"
      echo "retain_objc_accessible: false"
      echo "clean_build: false"
    } > "$CONFIG_FILE"

    good "Created $CONFIG_FILE (scheme=$DEFAULT_SCHEME, target=$DEFAULT_TARGET)"
  else
    warn ".periphery.yml not found. Launching interactive Periphery setup..."
    bold "(You will be prompted by Periphery. Choose workspace/project, scheme, and targets as usual.)"
    periphery scan --setup || { err "Periphery setup failed."; exit 1; }
    if [[ ! -f "$CONFIG_FILE" ]]; then
      err "Setup finished but .periphery.yml was not created. Aborting."
      exit 1
    fi
    good "Created $CONFIG_FILE via interactive setup"
  fi
else
  good "Found existing .periphery.yml"
fi

WORK_DIR="$ROOT_DIR/.periphery_cleanup"
mkdir -p "$WORK_DIR"
SCAN_JSON_1="$WORK_DIR/scan_1.json"
SCAN_JSON_2="$WORK_DIR/scan_2.json"
REPORT_TXT="$WORK_DIR/report.txt"
REMOVABLE_FILES_TXT="$WORK_DIR/removable_files.txt"
DELETED_SYMBOLS_TXT="$WORK_DIR/deleted_symbols.txt"
: > "$REPORT_TXT"; : > "$REMOVABLE_FILES_TXT"; : > "$DELETED_SYMBOLS_TXT"

# Keep artifacts out of source control by ensuring .gitignore contains the work directory
GITIGNORE_FILE="$ROOT_DIR/.gitignore"
if [[ -f "$GITIGNORE_FILE" ]]; then
  if ! grep -qE '^\.periphery_cleanup/?$' "$GITIGNORE_FILE" 2>/dev/null; then
    echo "# Periphery cleanup artifacts" >> "$GITIGNORE_FILE"
    echo ".periphery_cleanup/" >> "$GITIGNORE_FILE"
    good "Updated .gitignore to ignore .periphery_cleanup/"
  fi
else
  {
    echo "# Periphery cleanup artifacts"
    echo ".periphery_cleanup/"
  } > "$GITIGNORE_FILE"
  good "Created .gitignore to ignore .periphery_cleanup/"
fi

bold "\nRunning Periphery scan (pass 1)..."
periphery scan --config "$CONFIG_FILE" --format json --disable-update-check > "$SCAN_JSON_1" || {
  err "Periphery scan failed."
  exit 1
}
good "Scan completed. Output: $SCAN_JSON_1"

# 3) Parse JSON and annotate unused declarations safely with @available(*, deprecated, ...)
#    Use Python for robust JSON parsing and in-place edits.
PYTHON3_BIN="python3"
if ! command -v "$PYTHON3_BIN" >/dev/null 2>&1; then
  err "python3 not found. Please install Python 3."
  exit 1
fi

cat > "$WORK_DIR/annotate.py" <<'PY'
import json, os, sys, re

scan_path = sys.argv[1]
deleted_log_path = sys.argv[2]

with open(scan_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Group entries by file
entries_by_file = {}
for e in data:
    loc = e.get('location', '')
    # Periphery sometimes splits lines with wrapping; normalize
    # Expect: /abs/path/File.swift:LINE:COL
    m = re.search(r"(.+\.swift):(\d+):(\d+)$", loc)
    if not m:
        continue
    path, line, col = m.group(1), int(m.group(2)), int(m.group(3))
    entries_by_file.setdefault(path, []).append({
        'line': line,
        'col': col,
        'name': e.get('name',''),
        'kind': e.get('kind',''),
        'hints': e.get('hints', []),
        'accessibility': e.get('accessibility','')
    })

deleted = []

def is_stored_property_line(line: str) -> bool:
    # Single-line stored property like: `public var foo: Type = ...` or `let name = ...`
    # Avoid computed properties `{` and protocol requirements `get set` patterns
    s = line.strip()
    if not re.search(r"\b(var|let)\b", s):
        return False
    if '{' in s:
        return False
    if re.search(r"\b(get|set)\b", s):
        return False
    return '=' in s

applied = []

for path, entries in entries_by_file.items():
    if not os.path.isfile(path):
        continue
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception:
        continue

    # For @Observable files, we DO allow deletions of unused stored properties.

    # Sort entries descending by line to keep indices stable when inserting
    entries.sort(key=lambda x: x['line'], reverse=True)

    changed = False
    for e in entries:
        line_idx = e['line'] - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        decl_line = lines[line_idx]
        hints = set(h.lower() for h in e.get('hints', []))

        # 1) Remove unused imports (only when explicitly marked unused)
        if decl_line.lstrip().startswith('import ') and 'unused' in hints:
            del lines[line_idx]
            changed = True
            deleted.append(f"{path}:{e['line']} import {e.get('name','')}")
            continue

        # 2) Remove single-line stored properties only if explicitly unused
        if is_stored_property_line(decl_line) and 'unused' in hints:
            del lines[line_idx]
            changed = True
            deleted.append(f"{path}:{e['line']} var/let {e.get('name','')}")
            continue

    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

with open(deleted_log_path, 'w', encoding='utf-8') as f:
    for a in deleted:
        f.write(a + "\n")

# Compute removable file candidates conservatively:
# If a file contains exactly one top-level type declaration (struct/class/enum/protocol),
# and that same declaration appears in the unused report, suggest it.
def top_level_decl_count(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            src = f.read()
    except Exception:
        return 0
    # Remove comments to avoid false positives
    src = re.sub(r"//.*", "", src)
    src = re.sub(r"/\*[\s\S]*?\*/", "", src)
    m = re.findall(r"^\s*(struct|class|enum|protocol)\s+\w+", src, flags=re.MULTILINE)
    return len(m)

removable_candidates = []
for path, entries in entries_by_file.items():
    # Only consider if file still exists and exactly one top-level decl
    if not os.path.isfile(path):
        continue
    if top_level_decl_count(path) != 1:
        continue
    # If every entry in this file is an unused type (struct/class/enum/protocol)
    all_types_unused = all(any(k in e['kind'] for k in ['struct', 'class', 'enum', 'protocol']) for e in entries)
    if all_types_unused:
        removable_candidates.append(path)

print("\n\n===REPORT-BEGIN===")
print(json.dumps({
    'deleted_count': sum(1 for _ in open(deleted_log_path, 'r', encoding='utf-8')) if os.path.isfile(deleted_log_path) else 0,
    'removable_candidates': removable_candidates
}, indent=2))
print("===REPORT-END===\n\n")
PY

if [[ -s "$SCAN_JSON_1" ]] && grep -q '"kind"' "$SCAN_JSON_1"; then
  python3 "$WORK_DIR/annotate.py" "$SCAN_JSON_1" "$DELETED_SYMBOLS_TXT" | tee -a "$REPORT_TXT" >/dev/null
else
  warn "No unused items found by Periphery (empty JSON). Skipping annotation."
  echo "\n===REPORT-BEGIN===" >> "$REPORT_TXT"
  echo '{"deleted_count":0,"removable_candidates":[]}' >> "$REPORT_TXT"
  echo "===REPORT-END===\n" >> "$REPORT_TXT"
fi

REMOVABLE_JSON=$(sed -n '/===REPORT-BEGIN===/,/===REPORT-END===/p' "$REPORT_TXT" | sed '1d;$d')
echo "$REMOVABLE_JSON" > "$WORK_DIR/removable.json"
"$PYTHON3_BIN" - "$WORK_DIR/removable.json" <<'PY' > "$WORK_DIR/removable_extracted.txt"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
print("Deleted symbols:", d.get('deleted_count',0))
print("\nPotentially removable files (manual delete, safe heuristic):")
for p in d.get('removable_candidates',[]):
    print(p)
PY

cat "$WORK_DIR/removable_extracted.txt" | tee "$REMOVABLE_FILES_TXT"

# Remove transient helper files
rm -f "$WORK_DIR/removable_extracted.txt" "$WORK_DIR/removable.json" "$WORK_DIR/annotate.py"

bold "\nRunning Periphery scan (pass 2, verification)..."
periphery scan --config "$CONFIG_FILE" --format json --disable-update-check > "$SCAN_JSON_2" || {
  err "Periphery verification scan failed."
  exit 1
}
good "Verification scan completed. Output: $SCAN_JSON_2"

# Basic loop avoidance: only two scans are performed.
# Summarize counts before/after

COUNT1=$(grep -c '"kind"' "$SCAN_JSON_1" || true)
COUNT2=$(grep -c '"kind"' "$SCAN_JSON_2" || true)

echo "" | tee -a "$REPORT_TXT"
bold "Summary"
echo "- Unused reported (pass 1): $COUNT1" | tee -a "$REPORT_TXT"
echo "- Unused reported (pass 2): $COUNT2" | tee -a "$REPORT_TXT"
DELETED_COUNT=$(wc -l < "$DELETED_SYMBOLS_TXT" | tr -d ' ')
echo "- Deleted symbols: $DELETED_COUNT" | tee -a "$REPORT_TXT"
echo "- Removable file candidates listed in: $REMOVABLE_FILES_TXT" | tee -a "$REPORT_TXT"

cat <<'EOT'

============================================================
 Result
============================================================
  • Deleted clearly unused imports and single-line stored properties.
  • Listed conservative whole-file removals where the file contains a
    single unused top-level type (manual review recommended).
  • To review:
      - .periphery_cleanup/deleted_symbols.txt
      - .periphery_cleanup/removable_files.txt
      - .periphery_cleanup/scan_2.json

 Tips
  - Re-run this script after code changes.
  - For whole-file deletion, confirm in Xcode first, then delete.

============================================================
EOT

good "Periphery cleanup complete."


