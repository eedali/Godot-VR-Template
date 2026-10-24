#!/usr/bin/env bash
# Runs the Godot console binary with the given arguments.
#
# Resolution order:
#   1. $GODOT_BIN (set in .claude/settings.json)
#   2. Known install locations on this machine
#   3. `godot` on PATH
#
# Usage: bash tools/godot.sh --headless --path . --import
set -euo pipefail

candidates=(
	"${GODOT_BIN:-}"
	"C:/Open/Godot_v4.6-stable_win64_console.exe"
	"/c/Open/Godot_v4.6-stable_win64_console.exe"
	"C:/Open/Godot_v4.6-stable_win64.exe"
	"/c/Open/Godot_v4.6-stable_win64.exe"
	"$(command -v godot 2>/dev/null || true)"
	"$(command -v godot4 2>/dev/null || true)"
)

for bin in "${candidates[@]}"; do
	if [ -n "$bin" ] && [ -f "$bin" ]; then
		exec "$bin" "$@"
	fi
done

echo "tools/godot.sh: Godot binary not found." >&2
echo "Set GODOT_BIN to the console build, e.g. C:/Open/Godot_v4.6-stable_win64_console.exe" >&2
exit 127
