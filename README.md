# fe-setup

One-shot installer that gets a Mac ready to work on the Omne frontend with Claude Code. Aimed at designers, but anyone on macOS can use it.

## 1. Open Terminal

Press `Cmd + Space` to open Spotlight. Type `Terminal` and press `Return`. A window with a prompt appears — that's where you'll paste the command in the next step.

## 2. Run the install command

Paste this into Terminal and press `Return`:

```bash
curl -fsSL https://raw.githubusercontent.com/nalper-omnesoft/fe-setup/main/setup.sh -o ~/Downloads/fe-setup.sh && bash ~/Downloads/fe-setup.sh
```

You'll see colored `✓` marks as each step completes. The whole thing takes ~5–10 minutes.

If a dialog pops up asking to install **Xcode Command Line Tools**, click `Install`, wait for it to finish, then re-run the same command in the Terminal window:

```bash
bash ~/Downloads/fe-setup.sh
```

## 3. After it finishes, open Warp

When the script is done you'll see a green `━━━ Tooling ready. ━━━` message at the bottom of Terminal. That's your cue.

**Quit Terminal** (`Cmd + Q`), then open Warp — it's a modern terminal that's friendlier for what comes next. Press `Cmd + Space`, type `Warp`, press `Return`. Sign in with your work email on first launch.

From now on, use Warp instead of the built-in Terminal.

## 4. Sign in to GitHub

In Warp, sign in to GitHub:

```bash
gh auth login
```

Choose: **GitHub.com → HTTPS → Login with a web browser**.

## 5. Sign up for Vercel

You'll need a Vercel account to deploy prototypes. From Warp:

```bash
open https://vercel.com/signup
```

Use **Continue with GitHub** so it's the same account as step 4. Then link the CLI to that account:

```bash
vercel login
```

## 6. Clone the repo

```bash
mkdir -p ~/repos/omne && cd ~/repos/omne
gh repo clone omnesoft/omne-frontend
cd omne-frontend && pnpm install
```

## 7. Start your designer session

From anywhere in Warp:

```bash
designstart "Sam working on the inventory module"
```

Replace `Sam working on the inventory module` with your name and the feature you want to design.

This `cd`s into the frontend repo and launches Claude Code with the designer onboarding prompt. Claude will cut you a `prototype/` branch, enable the dev auth bypass, and start the dev server — you're ready to design.

First time only: a browser opens for Claude sign-in. Use your work email.

---

## What the script does

In order:

1. **Xcode Command Line Tools** — Apple's compilers, needed by Homebrew. If missing, triggers Apple's installer and asks you to re-run.
2. **Homebrew** — package manager for macOS. Installed and added to `~/.zprofile` so future shells find it.
3. **CLI tools via Homebrew** — `node`, `pnpm`, `git`, `gh` (GitHub CLI).
4. **GUI apps via Homebrew Cask** — Cursor, Fork, Ghostty, Warp (all installed into `/Applications`).
5. **Claude Code** — installed globally via `npm` (the `claude` command).
6. **Vercel CLI** — installed globally via `npm` (the `vercel` command).
7. **Shell helpers added to `~/.zshrc`**:
   - `claudeyolo` — shortcut for `claude --dangerously-skip-permissions`.
   - `bup` — update Homebrew, all packages, and Claude Code in one go.
   - `designstart "<your name> working on <feature>"` — `cd` into the frontend repo and launch Claude with the right onboarding prompt.
   - `HOMEBREW_CASK_OPTS="--no-quarantine"` — skips Gatekeeper's "are you sure?" prompt for cask installs.
8. **Verifies** every tool resolves on PATH.

Safe to re-run — every step skips work that's already done.

## Check without changing anything

To report what's installed and what's missing without making changes:

```bash
bash ~/Downloads/fe-setup.sh --check
```

## Troubleshooting

The script writes a full log to `/tmp/omne-designer-setup.log`. If something fails, paste the log into `#design-systems-eng` on Slack.
