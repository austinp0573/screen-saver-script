#!/usr/bin/env bash
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/austinp0573/screen-saver-script/main/myclock.py"
PY_NAME="myclock.py"
SERVICE_NAME="clock-writer.service"

USER_HOME="$HOME"
BIN_DIR="$USER_HOME/screen-saver-dir"
PY_PATH="$BIN_DIR/$PY_NAME"
SYSD_DIR="$USER_HOME/.config/systemd/user"
XSC="$USER_HOME/.xscreensaver"
BACKUP="${XSC}.bak.$(date +%s)"

phos_path() {
  if [ -x /usr/libexec/xscreensaver/phosphor ]; then
    echo /usr/libexec/xscreensaver/phosphor
  elif [ -x /usr/lib/xscreensaver/phosphor ]; then
    echo /usr/lib/xscreensaver/phosphor
  else
    echo ""
  fi
}

set_pref() {
  local key="$1" val="$2"
  if [ -f "$XSC" ] && grep -q "^$key:" "$XSC"; then
    sed -i "s|^$key:.*|$key:\t$val|g" "$XSC"
  else
    printf "%s:\t%s\n" "$key" "$val" >>"$XSC"
  fi
}

append_or_replace_custom() {
  local label="custom" cmdline="$1"
  if grep -q "\"$label\"" "$XSC" 2>/dev/null; then
    sed -i "s#\"$label\".*#\"$label\"  $cmdline  \\\\#g" "$XSC"
  else
    if grep -q "^programs:" "$XSC" 2>/dev/null; then
      printf "\"%s\"  %s  \\\\\n" "$label" "$cmdline" >>"$XSC"
    else
      printf "programs: \\\\\n\"%s\"  %s  \\\\\n" "$label" "$cmdline" >>"$XSC"
    fi
  fi
}

sudo apt-get update -y
sudo apt-get install -y curl python3 xscreensaver xscreensaver-data xscreensaver-data-extra

PHOS="$(phos_path)"
[ -n "$PHOS" ] || { echo "phosphor not found"; exit 1; }

mkdir -p "$BIN_DIR"
curl -fsSL "$RAW_URL" -o "$PY_PATH"
chmod +x "$PY_PATH"

mkdir -p "$SYSD_DIR"
cat >"$SYSD_DIR/$SERVICE_NAME" <<EOF
[Unit]
Description=Clock writer
After=default.target

[Service]
Type=simple
ExecStart=$PY_PATH
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

if [ ! -f "$XSC" ]; then
  nohup xscreensaver -no-splash >/dev/null 2>&1 &
  sleep 1
  xscreensaver-command -exit >/dev/null 2>&1 || true
  [ -f "$XSC" ] || : >"$XSC"
fi

cp -f "$XSC" "$BACKUP"

set_pref "timeout" "0:05:00"
set_pref "cycle" "0:00:00"
set_pref "lock" "True"
set_pref "lockTimeout" "0:30:00"
set_pref "passwdTimeout" "0:00:30"
set_pref "visualID" "default"
set_pref "installColormap" "True"
set_pref "verbose" "False"
set_pref "splash" "True"
set_pref "splashDuration" "0:00:05"
set_pref "demoCommand" "xscreensaver-settings"
set_pref "nice" "10"
set_pref "fade" "False"
set_pref "unfade" "False"
set_pref "fadeSeconds" "0:00:03"
set_pref "ignoreUninstalledPrograms" "False"
set_pref "dpmsEnabled" "False"
set_pref "dpmsQuickOff" "False"
set_pref "dpmsStandby" "2:00:00"
set_pref "dpmsSuspend" "2:00:00"
set_pref "dpmsOff" "4:00:00"
set_pref "grabDesktopImages" "False"
set_pref "grabVideoFrames" "False"
set_pref "chooseRandomImages" "False"
set_pref "imageDirectory" ""
set_pref "mode" "one"
set_pref "selected" "255"
set_pref "textMode" "file"
set_pref "textLiteral" "XScreenSaver"
set_pref "textFile" "$BIN_DIR/current_time.txt"
set_pref "textProgram" "fortune"
set_pref "textURL" "https://planet.debian.org/rss20.xml"
set_pref "dialogTheme" "default"
set_pref "settingsGeom" "1920,34 3106,34"

PHOS_CMD="phosphor --root -esc -scale 10 -ticks 10 -delay 150000"
if grep -q '^phosphorCommand:' "$XSC"; then
  sed -i "s#^phosphorCommand:.*#phosphorCommand:\t$PHOS_CMD#" "$XSC"
else
  printf "phosphorCommand:\t%s\n" "$PHOS_CMD" >>"$XSC"
fi

sed -i '/^mode:/c\mode:\tone' "$XSC" || echo -e "mode:\tone" >>"$XSC"

echo "done (backup: $BACKUP)"