#!/usr/bin/env bash
# Claude Code installer for Omne designers (macOS).
#
# Installs every tool from DESIGNERS_GUIDE.md sections 1.2-1.6:
#   - Xcode Command Line Tools (triggers the install dialog)
#   - Homebrew (+ adds it to your PATH)
#   - Node.js, pnpm, git, GitHub CLI
#   - Claude Code (the `claude` command)
#   - Cursor (the editor)
#
# Safe to re-run. Every step checks for what's already installed and skips it.
#
# Usage:
#   bash setup.sh           # install everything
#   bash setup.sh --check   # report what's installed without changing anything
#
# Logs to /tmp/omne-designer-setup.log. If you get stuck, paste the log into
# #design-systems-eng.

# Fail pipelines if any stage fails (otherwise `... | tee log` hides install errors).
set -o pipefail

LOG_FILE="/tmp/omne-designer-setup.log"
: > "$LOG_FILE"  # truncate

# ---- pretty output -----------------------------------------------------------
if [[ -t 1 ]]; then
  CYAN=$'\033[36m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
else
  CYAN= GREEN= YELLOW= RED= BOLD= DIM= RESET=
fi

step() { printf '\n%s%s▶ %s%s\n' "$CYAN" "$BOLD" "$1" "$RESET"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
skip() { printf '  %s↷%s %s\n' "$DIM" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
fail() {
  printf '  %s✗%s %s\n' "$RED" "$RESET" "$1" >&2
  printf '    %sFull log: %s%s\n' "$DIM" "$LOG_FILE" "$RESET" >&2
}

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

run_and_log() {
  # Run a command; tee its output to the log; return its exit code.
  log "RUN: $*"
  "$@" >> "$LOG_FILE" 2>&1
}

# ---- mode --------------------------------------------------------------------
CHECK_ONLY=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
fi

# ---- header ------------------------------------------------------------------
printf '%s%s' "$BOLD" "$CYAN"
cat <<'EOF'

  ╭───────────────────────────────────────────────────╮
  │  Claude Code setup — for Omne designers           │
  │  Installs the tools you need. Safe to re-run.     │
  ╰───────────────────────────────────────────────────╯
EOF
printf '%s\n' "$RESET"

if [[ $CHECK_ONLY -eq 1 ]]; then
  printf '%sCheck mode — nothing will be installed or changed.%s\n' "$DIM" "$RESET"
fi

# ---- sanity check: macOS -----------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "This script is macOS-only. Detected: $(uname -s)"
  exit 1
fi

# ---- step 1: Xcode CLT -------------------------------------------------------
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "already installed"
else
  if [[ $CHECK_ONLY -eq 1 ]]; then
    fail "not installed — run setup.sh (without --check) to install"
  else
    warn "Triggering the Apple installer dialog."
    warn "Click 'Install' when it appears, accept the license, and wait for it to finish."
    warn "Then re-run this script."
    xcode-select --install >/dev/null 2>&1 || true
    exit 0
  fi
fi

# ---- step 2: Homebrew --------------------------------------------------------
step "Homebrew"

# Pick the correct Homebrew prefix for this Mac.
if [[ "$(uname -m)" == "arm64" ]]; then
  HB_PREFIX=/opt/homebrew  # Apple Silicon
else
  HB_PREFIX=/usr/local      # Intel
fi

# Make sure brew is on PATH for this session even if .zprofile hasn't been sourced yet.
if [[ -x "$HB_PREFIX/bin/brew" ]] && ! command -v brew >/dev/null 2>&1; then
  eval "$("$HB_PREFIX/bin/brew" shellenv)"
fi

if command -v brew >/dev/null 2>&1; then
  ok "already installed ($(brew --version | head -n1))"
else
  if [[ $CHECK_ONLY -eq 1 ]]; then
    fail "not installed"
  else
    warn "Installing Homebrew. macOS will ask for your Mac login password."
    warn "Your cursor won't move while you type — that's normal. Press Return when done."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"; then
      eval "$("$HB_PREFIX/bin/brew" shellenv)"
      ok "Homebrew installed"
    else
      fail "Homebrew install failed. Ping #design-systems-eng and attach the log."
      exit 1
    fi
  fi
fi

# Make sure future Terminal sessions find brew too.
if [[ $CHECK_ONLY -eq 0 ]] && command -v brew >/dev/null 2>&1; then
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    {
      echo ""
      echo "# Homebrew (added by Claude Code designer setup)"
      echo "eval \"\$($HB_PREFIX/bin/brew shellenv)\""
    } >> "$HOME/.zprofile"
    ok "added Homebrew to ~/.zprofile"
  else
    skip "Homebrew already in ~/.zprofile"
  fi
fi

# ---- step 3: brew packages ---------------------------------------------------
step "Tools: node, pnpm, git, gh"

# Anything not on PATH after install? Bail; user needs a fresh shell or our PATH setup didn't work.
if ! command -v brew >/dev/null 2>&1; then
  fail "brew not on PATH. Open a new Terminal window and re-run this script."
  exit 1
fi

PKGS=(node pnpm git gh)
for pkg in "${PKGS[@]}"; do
  if brew list "$pkg" >/dev/null 2>&1; then
    ok "$pkg already installed"
  else
    if [[ $CHECK_ONLY -eq 1 ]]; then
      fail "$pkg not installed"
    else
      printf '  %s…%s installing %s\n' "$DIM" "$RESET" "$pkg"
      if run_and_log brew install "$pkg"; then
        ok "$pkg installed"
      else
        fail "$pkg install failed. See log for details."
        exit 1
      fi
    fi
  fi
done

# ---- step 4: casks ----------------------------------------------------------

step "GUI apps: Cursor, Fork, Ghostty, Warp"

# Format: cask|app_path|shell_command (empty when the app has no command-palette
# "Install … command in PATH" entry, e.g. Fork).
CASKS=(
  "fork|/Applications/Fork.app|"
  "ghostty|/Applications/Ghostty.app|"
  "warp|/Applications/Warp.app|"
  "cursor|/Applications/Cursor.app|cursor"
)

for item in "${CASKS[@]}"; do
  IFS="|" read -r cask app_path command_name <<< "$item"
  app_name="$(basename "$app_path" .app)"

  if brew list --cask "$cask" >/dev/null 2>&1; then
    ok "$app_name already installed"
  elif [[ -d "$app_path" ]]; then
    ok "$app_name already installed in /Applications, not via Homebrew"
  else
    if [[ $CHECK_ONLY -eq 1 ]]; then
      fail "$app_name not installed"
    else
      printf '  %s…%s installing %s via Homebrew cask\n' "$DIM" "$RESET" "$app_name"

      if run_and_log brew install --cask "$cask"; then
        ok "$app_name installed in /Applications"

        if [[ -n "$command_name" ]]; then
          warn "After opening $app_name once, run 'Shell Command: Install \"$command_name\" command in PATH'"
          warn "from its Command Palette (Cmd+Shift+P) to use '$command_name .' from Terminal."
        fi
      else
        fail "$app_name install failed. See log for details."
        exit 1
      fi
    fi
  fi
done

# ---- step 5: Claude Code -----------------------------------------------------
step "Claude Code"

if command -v claude >/dev/null 2>&1; then
  version="$(claude --version 2>/dev/null | head -n1 || echo 'version unknown')"
  ok "already installed ($version)"
else
  if [[ $CHECK_ONLY -eq 1 ]]; then
    fail "not installed"
  else
    printf '  %s…%s installing via npm (this takes about a minute)\n' "$DIM" "$RESET"
    if run_and_log npm install -g @anthropic-ai/claude-code; then
      ok "Claude Code installed"
    else
      fail "Claude Code install failed."
      fail "If you see 'EACCES', npm needs permission to write globally."
      fail "Ping #design-systems-eng with the log."
      exit 1
    fi
  fi
fi

# ---- step 6: shell helpers --------------------------------------------------
step "Shell helpers in ~/.zshrc"

ZSHRC_ENTRIES=(
  'alias claudeyolo="claude --dangerously-skip-permissions"'
  'alias bup="brew update && brew upgrade --greedy && brew cleanup && claude update"'
  'export HOMEBREW_CASK_OPTS="--no-quarantine"'
)

zshrc_header_added=0
for entry in "${ZSHRC_ENTRIES[@]}"; do
  # Match the bit before '=' (e.g. 'alias claudeyolo', 'export HOMEBREW_CASK_OPTS')
  # so we don't duplicate it if the user already defined it differently.
  key="${entry%%=*}"
  if grep -qF "$key" "$HOME/.zshrc" 2>/dev/null; then
    skip "$key already in ~/.zshrc"
  else
    if [[ $CHECK_ONLY -eq 1 ]]; then
      fail "$key not in ~/.zshrc"
    else
      if [[ $zshrc_header_added -eq 0 ]]; then
        {
          echo ""
          echo "# Claude Code helpers (added by Claude Code designer setup)"
        } >> "$HOME/.zshrc"
        zshrc_header_added=1
      fi
      echo "$entry" >> "$HOME/.zshrc"
      ok "added $key to ~/.zshrc"
    fi
  fi
done

# designstart() is a multi-line shell function, so it can't ride in the array above.
if grep -qE '^designstart\s*\(\s*\)' "$HOME/.zshrc" 2>/dev/null; then
  skip "designstart() already in ~/.zshrc"
else
  if [[ $CHECK_ONLY -eq 1 ]]; then
    fail "designstart() not in ~/.zshrc"
  else
    if [[ $zshrc_header_added -eq 0 ]]; then
      {
        echo ""
        echo "# Claude Code helpers (added by Claude Code designer setup)"
      } >> "$HOME/.zshrc"
      zshrc_header_added=1
    fi
    cat >> "$HOME/.zshrc" <<'EOF'
designstart() {
  cd ~/repos/omne/omne-frontend || return 1
  claude --dangerously-skip-permissions "I'm a designer, $*"
}
EOF
    ok "added designstart() to ~/.zshrc"
  fi
fi

# ---- step 7: verify ---------------------------------------------------------
step "Verifying everything works"

verify_ok=1
for cmd in brew node pnpm git gh claude; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd: $(command -v "$cmd")"
  else
    fail "$cmd: NOT FOUND"
    verify_ok=0
  fi
done

if [[ $verify_ok -eq 0 ]]; then
  fail "Some tools didn't make it onto your PATH."
  printf '    %sClose this Terminal window, open a new one, and run:%s\n' "$DIM" "$RESET" >&2
  printf '    %s  bash <path-to>/setup.sh --check%s\n' "$DIM" "$RESET" >&2
  exit 1
fi

# ---- summary -----------------------------------------------------------------
echo ""
printf '%s%s━━━ Tooling ready. ━━━%s\n\n' "$GREEN" "$BOLD" "$RESET"

if [[ $CHECK_ONLY -eq 1 ]]; then
  printf '%sEverything you need is installed.%s\n\n' "$DIM" "$RESET"
  exit 0
fi

printf '%sWhat got installed:%s\n' "$BOLD" "$RESET"
printf '  • Xcode Command Line Tools\n'
printf '  • Homebrew\n'
printf '  • Node.js, pnpm, git, GitHub CLI\n'
printf '  • Claude Code (the %sclaude%s command)\n' "$CYAN" "$RESET"
printf '  • Cursor (in /Applications)\n\n'

printf '%sWhat to do next:%s\n\n' "$BOLD" "$RESET"

printf '  %s!%s %sOpen a new Terminal window first%s — your current shell predates the\n' "$YELLOW" "$RESET" "$BOLD" "$RESET"
printf '       new PATH entries and aliases (claudeyolo, bup), so none of the\n'
printf '       commands below will work until you do.\n\n'

printf '  %s1.%s Sign in to GitHub:\n' "$BOLD" "$RESET"
printf '       %sgh auth login%s\n' "$CYAN" "$RESET"
printf '       %s(Choose: GitHub.com → HTTPS → Login with a web browser)%s\n\n' "$DIM" "$RESET"

printf '  %s2.%s Clone the Omne repo:\n' "$BOLD" "$RESET"
printf '       %smkdir -p ~/repos/omne && cd ~/repos/omne%s\n' "$CYAN" "$RESET"
printf '       %sgh repo clone omnesoft/omne-frontend%s\n' "$CYAN" "$RESET"
printf '       %scd omne-frontend && pnpm install%s\n' "$CYAN" "$RESET"


printf '  %s3.%s Start Claude Code from inside the repo:\n' "$BOLD" "$RESET"
printf '       %sclaude%s\n' "$CYAN" "$RESET"
printf '       %sFirst time: a browser opens for sign-in. Use your work email.%s\n\n' "$DIM" "$RESET"

printf '  %s4.%s Open the repo in Cursor (optional, for browsing files):\n' "$BOLD" "$RESET"
printf '       %sopen -a Cursor ~/repos/omne/omne-frontend%s\n' "$CYAN" "$RESET"
printf '       %sFirst-time Cursor setup: skip the AI features — Claude Code does that part.%s\n\n' "$DIM" "$RESET"

printf '%sFull guide:%s apps/prototypes/DESIGNERS_GUIDE.md\n' "$DIM" "$RESET"
printf '%sSetup log:%s  %s\n' "$DIM" "$RESET" "$LOG_FILE"
printf '%sStuck?%s     #design-systems-eng on Slack\n\n' "$DIM" "$RESET"
