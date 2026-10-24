#!/usr/bin/env bash
# Installs the Godot OpenXR Vendors addon into addons/godotopenxrvendors
# (gitignored; needed for the Android/Quest export). Safe to re-run.
#
# The version must match OPENXR_VENDORS_VERSION in
# .github/workflows/publish-demo-on-push.yaml and the README.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

VERSION="${OPENXR_VENDORS_VERSION:-4.3.0-stable}"
TARGET="addons/godotopenxrvendors"
URL="https://github.com/GodotVR/godot_openxr_vendors/releases/download/${VERSION}/godotopenxrvendorsaddon.zip"

if [ -f "$TARGET/plugin.cfg" ]; then
	echo "OpenXR Vendors already installed: $(grep -E '^version=' "$TARGET/plugin.cfg" || echo "$TARGET")"
	exit 0
fi

tmp="$(mktemp -d)"
echo "Downloading OpenXR Vendors ${VERSION} ..."
curl -fL --retry 3 -o "$tmp/vendors.zip" "$URL"

echo "Extracting ..."
if command -v unzip > /dev/null 2>&1; then
	unzip -q -o "$tmp/vendors.zip" -d "$tmp/x"
elif command -v powershell.exe > /dev/null 2>&1; then
	win_zip="$(cygpath -w "$tmp/vendors.zip")"
	win_out="$(cygpath -w "$tmp/x")"
	powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '$win_zip' -DestinationPath '$win_out' -Force"
else
	echo "Neither unzip nor powershell.exe found; cannot extract." >&2
	exit 1
fi

mkdir -p addons
rm -rf "$TARGET"
mv "$tmp/x/asset/addons/godotopenxrvendors" "$TARGET"
rm -rf "$tmp"
echo "Installed to $TARGET"
