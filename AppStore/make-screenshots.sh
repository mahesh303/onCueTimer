#!/bin/zsh
# Regenerates the App Store screenshots in AppStore/Screenshots.
#
#   AppStore/make-screenshots.sh [simulator-udid]
#
# Uses a 13-inch iPad simulator (default: the first "iPad Air 13-inch" or
# "iPad Pro 13-inch" found), sets a clean 9:41 status bar, runs the
# AppStoreScreenshots UI test, then rotates the images to landscape and strips
# their orientation metadata (App Store Connect and some viewers would
# otherwise show them sideways).
set -euo pipefail
cd "$(dirname "$0")/.."

device="${1:-$(xcrun simctl list devices available | grep -E 'iPad (Air|Pro) 13-inch' | tail -1 | grep -oE '[0-9A-F-]{36}')}"
raw="$(mktemp -d)"

xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b >/dev/null
xcrun simctl status_bar "$device" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100

TEST_RUNNER_SCREENSHOT_DIR="$raw" xcodebuild test \
    -project SpeechCueTimer.xcodeproj -scheme SpeechCueTimer \
    -destination "platform=iOS Simulator,id=$device" \
    -only-testing:SpeechCueTimerUITests/AppStoreScreenshots \
    -parallel-testing-enabled NO -quiet

mkdir -p AppStore/Screenshots
for f in "$raw"/*.png; do
    sips -r 270 "$f" --out "AppStore/Screenshots/$(basename "$f")" >/dev/null
done

# Drop metadata chunks (EXIF/XMP orientation) so the pixels are what everyone sees.
python3 -I - AppStore/Screenshots/*.png <<'PY'
import struct, sys
for path in sys.argv[1:]:
    data = open(path, "rb").read()
    out, i = [data[:8]], 8
    while i < len(data):
        length = struct.unpack(">I", data[i:i + 4])[0]
        kind = data[i + 4:i + 8]
        if kind not in (b"eXIf", b"iTXt", b"tEXt", b"zTXt"):
            out.append(data[i:i + 12 + length])
        i += 12 + length
    open(path, "wb").write(b"".join(out))
PY

xcrun simctl status_bar "$device" clear
rm -rf "$raw"
echo "Screenshots saved to AppStore/Screenshots"
