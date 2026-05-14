# fe-setup

One-shot installer that gets a Mac ready for working on the Omne frontend with Claude Code. Aimed at designers, but anyone on macOS can use it.

## Install

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/nalper-omnesoft/fe-setup/main/setup.sh -o ~/Downloads/fe-setup.sh && bash ~/Downloads/fe-setup.sh
```

If the script triggers the Xcode Command Line Tools installer, finish that dialog and then re-run:

```bash
bash ~/Downloads/fe-setup.sh
```

## Dry run

To see what's installed and what's missing without changing anything:

```bash
bash ~/Downloads/fe-setup.sh --check
```

## What it installs

- Xcode Command Line Tools
- Homebrew (added to `~/.zprofile` so future Terminal sessions find it)
- Node.js, pnpm, git, GitHub CLI
- Claude Code (the `claude` command)
- Cursor and Fork (in `/Applications`)
- Shell helpers in `~/.zshrc`: `claudeyolo`, `bup`, `HOMEBREW_CASK_OPTS`

The script is safe to re-run — every step skips work that's already done.

## After it finishes

Open a **new** Terminal window (so the new PATH and aliases load), then follow the on-screen "What to do next" steps to sign in to GitHub, clone the repo, and start Claude Code.

## Troubleshooting

The script writes a full log to `/tmp/omne-designer-setup.log`. If something fails, paste the log in `#design-systems-eng` on Slack.
