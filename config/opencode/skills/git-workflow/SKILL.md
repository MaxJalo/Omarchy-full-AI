---
name: Git Workflow
description: Inspect diffs, prepare clean Conventional Commits, manage branches/worktrees, and resolve merge conflicts safely
---

## Principles
1. Always inspect `git status` and `git diff` (staged and unstaged) before proposing or running a commit.
2. Never run destructive git commands (`push --force`, `reset --hard`, `clean -fd`) without explicit confirmation.
3. Never commit secrets (`.env`, API keys, tokens, private keys). Warn immediately if any are staged or tracked.

## Commit Format (Conventional Commits)
Use `<type>(<scope>): <imperative summary>` in lowercase, under 72 chars:
- `feat`: new feature or user-facing capability
- `fix`: bug fix
- `refactor`: structural improvement without behavior change
- `style`: UI/CSS/QML visual polish
- `docs`: documentation updates
- `chore`: tooling, dependencies, maintenance

Include a brief bulleted body only when explaining *why* a non-obvious decision was made.
