#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-run}"
case "$MODE" in
  run|debug|logs|telemetry|verify) ;;
  --debug|--logs|--telemetry|--verify) MODE="${MODE#--}" ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Espresso}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_EXEC="$APP_PATH/Contents/MacOS/$APP_NAME"
BUNDLE_ID="${BUNDLE_ID:-io.birki.espresso.dev}"

quit_existing() {
  if pgrep -f "$APP_EXEC" >/dev/null 2>&1; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    sleep 0.5
    pkill -f "$APP_EXEC" >/dev/null 2>&1 || true
  fi
}

build_app() {
  (cd "$ROOT_DIR" && script/build)
}

open_app() {
  /usr/bin/open -n "$APP_PATH"
}

quit_existing
build_app

case "$MODE" in
  run)
    open_app
    ;;
  debug)
    lldb -- "$APP_EXEC"
    ;;
  logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
esac
