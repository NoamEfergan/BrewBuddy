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
    info "brew install peripheryapp/periphery/periphery"
    brew install peripheryapp/periphery/periphery || {
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

# 2) Ensure .periphery.yml exists; if not, run interactive setup (normal Periphery flow)
CONFIG_FILE="$ROOT_DIR/.periphery.yml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  warn ".periphery.yml not found. Launching interactive Periphery setup..."
  bold "(You will be prompted by Periphery. Choose workspace/project, scheme, and targets as usual.)"
  periphery scan --setup || { err "Periphery setup failed."; exit 1; }
  if [[ ! -f "$CONFIG_FILE" ]]; then
    err "Setup finished but .periphery.yml was not created. Aborting."
    exit 1
  fi
  good "Created $CONFIG_FILE via interactive setup"
else
  good "Found existing .periphery.yml"
fi

WORK_DIR="$ROOT_DIR/.periphery_cleanup"
mkdir -p "$WORK_DIR"
SCAN_JSON_1="$WORK_DIR/scan_1.json"
SCAN_JSON_2="$WORK_DIR/scan_2.json"
REPORT_TXT="$WORK_DIR/report.txt"
REMOVABLE_FILES_TXT="$WORK_DIR/removable_files.txt"
APPLIED_MARKERS_TXT="$WORK_DIR/applied_markers.txt"
> "$REPORT_TXT"; > "$REMOVABLE_FILES_TXT"; > "$APPLIED_MARKERS_TXT"

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
applied_path = sys.argv[2]

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

# Heuristic-safe annotation: insert a @available(*, deprecated, ...) attribute
# on the line above the declaration if not already present.

def already_annotated(lines, idx):
    if idx-2 >= 0:
        prev = lines[idx-2].strip()
        if 'periphery-deprecated' in prev:
            return True
        if prev.startswith('@available(') and 'deprecated' in prev:
            return True
    return False

applied = []

for path, entries in entries_by_file.items():
    if not os.path.isfile(path):
        continue
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception:
        continue

    # Sort entries descending by line to keep indices stable when inserting
    entries.sort(key=lambda x: x['line'], reverse=True)

    changed = False
    for e in entries:
        line_idx = e['line'] - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        # Skip unless it's an obviously safe declaration to annotate
        # We limit to function/var/type declarations
        decl_line = lines[line_idx]
        if not re.search(r"\b(func|var|let|struct|class|enum|protocol|extension)\b", decl_line):
            continue

        if already_annotated(lines, line_idx+1):
            continue

        annotation = "@available(*, deprecated, message: \"Unused (Periphery)\") // periphery-deprecated\n"
        lines.insert(line_idx, annotation)
        changed = True
        applied.append(f"{path}:{e['line']} {e['kind']} {e['name']}")

    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

with open(applied_path, 'w', encoding='utf-8') as f:
    for a in applied:
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
    'applied_count': sum(1 for _ in open(applied_path, 'r', encoding='utf-8')) if os.path.isfile(applied_path) else 0,
    'removable_candidates': removable_candidates
}, indent=2))
print("===REPORT-END===\n\n")
PY

if [[ -s "$SCAN_JSON_1" ]] && grep -q '"kind"' "$SCAN_JSON_1"; then
  python3 "$WORK_DIR/annotate.py" "$SCAN_JSON_1" "$APPLIED_MARKERS_TXT" | tee -a "$REPORT_TXT" >/dev/null
else
  warn "No unused items found by Periphery (empty JSON). Skipping annotation."
  echo "\n===REPORT-BEGIN===" >> "$REPORT_TXT"
  echo '{"applied_count":0,"removable_candidates":[]}' >> "$REPORT_TXT"
  echo "===REPORT-END===\n" >> "$REPORT_TXT"
fi

REMOVABLE_JSON=$(sed -n '/===REPORT-BEGIN===/,/===REPORT-END===/p' "$REPORT_TXT" | sed '1d;$d')
echo "$REMOVABLE_JSON" | "$PYTHON3_BIN" - <<'PY' > "$WORK_DIR/removable_extracted.txt"
import json,sys
d=json.load(sys.stdin)
print("Applied annotations:", d.get('applied_count',0))
print("\nPotentially removable files (manual delete, safe heuristic):")
for p in d.get('removable_candidates',[]):
    print(p)
PY

cat "$WORK_DIR/removable_extracted.txt" | tee "$REMOVABLE_FILES_TXT"

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
APPLIED_COUNT=$(wc -l < "$APPLIED_MARKERS_TXT" | tr -d ' ')
echo "- Annotations applied: $APPLIED_COUNT" | tee -a "$REPORT_TXT"
echo "- Removable file candidates listed in: $REMOVABLE_FILES_TXT" | tee -a "$REPORT_TXT"

cat <<'EOT'

============================================================
 Result
============================================================
  • Added @available(*, deprecated, ...) markers above unused
    declarations to safely neutralize them without breaking builds.
  • Suggested conservative file deletions (manual) where the entire
    file appears to contain a single unused top-level type.
  • To review:
      - .periphery_cleanup/applied_markers.txt
      - .periphery_cleanup/removable_files.txt
      - .periphery_cleanup/scan_2.json

 Tips
  - Re-run this script after code changes.
  - For aggressive deletion, start from the suggested list and
    remove files in Xcode first, then from disk.

============================================================
EOT

good "Periphery cleanup complete."


