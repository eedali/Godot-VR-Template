#!/usr/bin/env bash
# Phase-0 git setup for autonomous Claude Code work:
#   * preserves any uncommitted local changes
#   * creates/switches to the work branch
#   * configures a credential helper so `git push` never asks for a password
#     in the terminal (Git Credential Manager stores the token in the Windows
#     Credential Manager after a one-time browser/GUI login)
# Safe to re-run.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

BRANCH="${CLAUDE_BRANCH:-claude/template-overhaul}"
export GIT_TERMINAL_PROMPT=0

echo "== git identity"
# Reuse the author of the last commit when no identity is configured.
if [ -z "$(git config user.name)" ]; then
	git config user.name "$(git log -1 --format=%an 2>/dev/null || echo eedali)"
fi
if [ -z "$(git config user.email)" ]; then
	git config user.email "$(git log -1 --format=%ae 2>/dev/null || echo eedali@users.noreply.github.com)"
fi
echo "user: $(git config user.name) <$(git config user.email)>"

echo "== credential helper"
helper="$(git config --get credential.helper || true)"
if [ -z "$helper" ]; then
	if git credential-manager --version > /dev/null 2>&1; then
		git config --global credential.helper manager
	elif command -v git-credential-manager-core > /dev/null 2>&1; then
		git config --global credential.helper manager-core
	else
		git config --global credential.helper wincred
	fi
	helper="$(git config --get credential.helper)"
	echo "configured credential.helper = $helper"
else
	echo "credential.helper already set: $helper"
fi
# Prefer the GitHub CLI's token when gh is logged in (no browser needed).
if command -v gh > /dev/null 2>&1 && gh auth status > /dev/null 2>&1; then
	gh auth setup-git > /dev/null 2>&1 && echo "gh auth setup-git: done"
fi

echo "== remote"
git remote -v | head -2

echo "== branch"
current="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current" = "$BRANCH" ]; then
	echo "already on $BRANCH"
else
	if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
		git checkout "$BRANCH"
	else
		git checkout -b "$BRANCH"
	fi
fi

echo "== preserving uncommitted local changes"
if [ -n "$(git status --porcelain)" ]; then
	git add -A
	git commit -q -m "chore: snapshot working tree (local changes + Claude Code tooling)" \
		-m "Snapshot of the working tree as found on the machine before automated work started, including the docs/claude plan package." \
		|| true
	echo "committed local changes on $BRANCH"
else
	echo "working tree clean"
fi

echo "== connectivity check (read-only)"
if git ls-remote --exit-code --heads origin > /dev/null 2>&1; then
	echo "origin reachable"
else
	echo "WARNING: origin not reachable right now; pushes will be retried later"
fi

git status -sb | head -3
