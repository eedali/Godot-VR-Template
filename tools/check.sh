#!/usr/bin/env bash
# Project verification for the Godot VR Template.
#
#   bash tools/check.sh            import + smoke test (scripts, scenes, resources) (+ gdlint if installed)
#   bash tools/check.sh --run      ... + run the main scene headless for a few seconds
#                                  + zone load test (start menu -> new game -> every zone)
#   bash tools/check.sh --export   ... + Windows debug export
#
# Exit code 0 means every mandatory check passed. Logs: build/claude-logs/
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

LOGS="build/claude-logs"
mkdir -p "$LOGS"
GODOT="bash tools/godot.sh"
# Running the project (smoke test, headless run) with OpenXR enabled and no
# headset pops up a blocking "OpenXR was requested but failed to start" alert
# on Windows. --xr-mode off skips OpenXR initialisation; XR Tools then takes
# the same "XR failed" desktop path it takes without a headset.
RUN_FLAGS="--headless --xr-mode off"
DO_EXPORT=0
DO_RUN=0
for arg in "$@"; do
	case "$arg" in
		--export) DO_EXPORT=1 ;;
		--run) DO_RUN=1 ;;
	esac
done

failures=0
step() { printf '\n== %s\n' "$1"; }
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# Lines that indicate a real problem in Godot output. Benign OpenXR/desktop
# fallback messages are intentionally not matched here.
ERROR_PATTERN='SCRIPT ERROR|Parse Error|Parser Error|Failed to load script|Failed loading resource|Failed to load resource|Resource file not found|Cannot open file|Error while loading|Invalid call|Nonexistent function|Identifier .* not declared|not found in base'

if ! $GODOT --version > "$LOGS/version.log" 2>&1; then
	fail "Godot binary not runnable (see $LOGS/version.log)"
	echo "Mandatory checks: $failures failure(s)"
	exit 1
fi
echo "Godot: $(tr -d '\r' < "$LOGS/version.log" | tail -1)"

# ---------------------------------------------------------------- 1. import
step "1/4 Import project"
$GODOT --headless --path . --import > "$LOGS/import.log" 2>&1
if grep -E -q "$ERROR_PATTERN" "$LOGS/import.log"; then
	grep -E "$ERROR_PATTERN" "$LOGS/import.log" | head -40
	fail "import produced errors (see $LOGS/import.log)"
else
	pass "import"
fi

# ------------------------------------------------------------- 3. smoke test
step "2/4 Smoke test (compile every script, load + instantiate every scene/resource)"
if $GODOT $RUN_FLAGS --path . --script res://tools/smoke_test.gd > "$LOGS/smoke.log" 2>&1; then
	grep -E "smoke_test:" "$LOGS/smoke.log" || true
	pass "smoke test"
else
	grep -E "FAIL:|smoke_test:|SCRIPT ERROR" "$LOGS/smoke.log" | head -40
	fail "smoke test (see $LOGS/smoke.log)"
fi

# ----------------------------------------------------------------- 4. gdlint
step "3/4 gdlint (optional)"
if command -v gdlint > /dev/null 2>&1; then
	if gdlint components config game tools > "$LOGS/gdlint.log" 2>&1; then
		pass "gdlint"
	else
		tail -40 "$LOGS/gdlint.log"
		fail "gdlint reported problems (see $LOGS/gdlint.log)"
	fi
else
	echo "gdlint not installed - skipped (optional; install with: pip install 'gdtoolkit==4.*')"
fi

# ------------------------------------------------------------ 5. run / export
step "4/4 Optional: run / export"
if [ "$DO_RUN" -eq 1 ]; then
	timeout 180 $GODOT $RUN_FLAGS --path . --quit-after 240 > "$LOGS/run.log" 2>&1
	if grep -E -q "SCRIPT ERROR|Parse Error" "$LOGS/run.log"; then
		grep -E "SCRIPT ERROR|Parse Error" -A3 "$LOGS/run.log" | head -60
		fail "headless run hit script errors (see $LOGS/run.log)"
	else
		pass "headless run (desktop fallback, OpenXR init failure is expected)"
	fi

	# Real game flow: start scene -> new game -> every zone in the database,
	# with the default features, with every feature on, and with a minimal
	# rig that frees disabled nodes (catches dangling references).
	zone_test() { # <log name> <description> [--set=...]
		local log="$LOGS/$1.log" what="$2"
		shift 2
		if timeout 300 $GODOT $RUN_FLAGS --path . --script res://tools/zone_load_test.gd -- "$@" > "$log" 2>&1 \
				&& ! grep -E -q "SCRIPT ERROR|Parse Error|previously freed" "$log"; then
			grep -E "zone_load_test: (zone loaded|runtime|[0-9]+ failure)" "$log" | tail -2 || true
			pass "zone load test: $what"
		else
			grep -E "FAIL:|zone_load_test:|SCRIPT ERROR|previously freed" -A3 "$log" | head -60
			fail "zone load test: $what (see $log)"
		fi
	}
	zone_test zones "default features"
	zone_test zones-all-on "every feature on" --set=all_on
	zone_test zones-minimal "minimal rig, remove_disabled_nodes" \
		--set=remove_disabled_nodes=true,player_body=false,pickup=false,pockets=false,collision_hands=false,hand_models=false,teleport=false,pointer=false,vignette=false
fi

if [ "$DO_EXPORT" -eq 1 ]; then
	mkdir -p build/windows
	rm -f build/windows/Game.exe build/windows/Game.pck
	timeout 900 $GODOT --headless --path . --export-debug "Windows" build/windows/Game.exe > "$LOGS/export-windows.log" 2>&1
	if [ -f build/windows/Game.exe ] && [ -f build/windows/Game.pck ]; then
		pass "Windows debug export -> build/windows/Game.exe"
	else
		tail -40 "$LOGS/export-windows.log"
		fail "Windows export did not produce Game.exe/Game.pck (see $LOGS/export-windows.log)"
	fi
fi

if [ "$DO_RUN" -eq 0 ] && [ "$DO_EXPORT" -eq 0 ]; then
	echo "skipped (use --run and/or --export)"
fi

# ---------------------------------------------------------------- summary
printf '\n'
if [ "$failures" -eq 0 ]; then
	echo "ALL CHECKS PASSED"
	exit 0
fi
echo "CHECKS FAILED: $failures"
exit 1
