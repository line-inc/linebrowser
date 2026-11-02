#!/bin/zsh
# Captures the 6 App Store screenshots on all three device classes.
#
# Robustness notes:
#  - `simctl terminate` can race with SpringBoard relaunching a frontmost app,
#    leaving a process whose argv has no --lb-shot (the screen then falls back
#    to the browser). We therefore kill by host PID, wait for the process to
#    actually disappear, and verify the new process's argv before shooting.
#  - Devices are erased first so shots start from a pristine state (no
#    accumulated tabs, no leftover preferences).
set -u

BUNDLE=com.lineinc.linebrowser
DEST_BASE=/Users/vladutzztech/Documents/LineBrowser/build/screenshots/appstore
APP=$(find ~/Library/Developer/Xcode/DerivedData/LineBrowser-*/Build/Products/Debug-iphonesimulator \
      -maxdepth 1 -name "LineBrowser.app" 2>/dev/null | head -1)

[[ -z "$APP" ]] && { echo "ERROR: no Debug .app found"; exit 1; }
echo "app: $APP"

DEVS=(
  "6.9-inch:3ACDA145-663A-441E-ADCB-E987EF849165"
  "6.3-inch:60EFC4C3-3C68-48DE-908B-8CED3E0AC995"
  "13-inch-ipad:0FEB8376-A16B-4BAC-A22A-3D8FA8A8FC3D"
)

SHOTS=(
  "01-web:web:24"
  "02-privacy:privacy:9"
  "03-netmonitor:netmonitor:9"
  "04-passwords:passwords:9"
  "05-vault:vault:9"
  "06-settings:settings:9"
)

app_pids() { # $1 = udid
  ps aux | grep "[L]ineBrowser.app/LineBrowser" | grep "$1" | awk '{print $2}'
}

kill_app() { # $1 = udid -> 0 when no process remains
  local udid=$1 pids i
  pids=$(app_pids "$udid")
  for pid in ${=pids}; do kill -9 "$pid" 2>/dev/null; done
  for i in $(seq 1 40); do
    [[ -z "$(app_pids "$udid")" ]] && return 0
    sleep 0.25
  done
  echo "    WARN: process would not die"
  return 1
}

launch_verified() { # $1 = udid, $2 = screen
  local udid=$1 screen=$2 attempt i
  for attempt in 1 2 3; do
    kill_app "$udid"
    xcrun simctl launch "$udid" "$BUNDLE" -- --lb-shot "$screen" >/dev/null 2>&1
    for i in $(seq 1 24); do
      if app_pids "$udid" | grep -q . && \
         ps aux | grep "[L]ineBrowser.app/LineBrowser" | grep "$udid" | grep -q -- "--lb-shot $screen"; then
        return 0
      fi
      sleep 0.25
    done
    echo "    retry $attempt for '$screen' (argv never matched)"
  done
  return 1
}

for d in "${DEVS[@]}"; do
  set_name="${d%%:*}"
  udid="${d##*:}"
  echo ""
  echo "=== $set_name ($udid) ==="

  # Pristine state: shutdown -> erase -> boot.
  xcrun simctl shutdown "$udid" >/dev/null 2>&1
  sleep 2
  xcrun simctl erase "$udid" >/dev/null 2>&1
  xcrun simctl boot "$udid" >/dev/null 2>&1
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1

  # English + a clean, consistent status bar for every shot.
  xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array "en" 2>/dev/null
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryLevel 100 \
      --cellularBars 4 --wifiBars 3 2>/dev/null

  xcrun simctl install "$udid" "$APP" || { echo "  install failed"; continue; }

  for s in "${SHOTS[@]}"; do
    name="${s%%:*}"; rest="${s#*:}"; screen="${rest%%:*}"; wait="${rest##*:}"
    if ! launch_verified "$udid" "$screen"; then
      echo "  FAIL launch $screen"; continue
    fi
    sleep "$wait"
    if xcrun simctl io "$udid" screenshot "$DEST_BASE/$set_name/$name.png" >/dev/null 2>&1; then
      echo "  ok  $name.png"
    else
      echo "  FAIL screenshot $name.png"
    fi
  done
  kill_app "$udid"
done

echo ""
echo "=== dimensions ==="
for d in "${DEVS[@]}"; do
  set_name="${d%%:*}"
  printf "%-14s " "$set_name"
  sips -g pixelWidth -g pixelHeight "$DEST_BASE/$set_name/01-web.png" 2>/dev/null | tail -2 | tr -d '\n' | sed 's/  */ /g'
  echo ""
done
