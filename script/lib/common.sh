#!/usr/bin/env bash

set -euo pipefail

require_macos() {
  local mode="${1:-error}"
  local message="${2:-}"

  if [[ "$(uname -s)" != "Darwin" ]]; then
    if [[ "$mode" == "skip" ]]; then
      if [[ -n "$message" ]]; then
        echo -e "${YELLOW}${message}${OFF}"
      else
        echo -e "${YELLOW}Skipping on non-macOS host.${OFF}"
      fi
      exit 0
    fi

    if [[ -n "$message" ]]; then
      echo -e "${RED}${message}${OFF}"
    else
      echo -e "${RED}This script requires macOS.${OFF}"
    fi
    exit 1
  fi
}

require_tool() {
  local tool="$1"
  local message="${2:-${tool} not found.}"

  if ! command -v "$tool" >/dev/null 2>&1; then
    echo -e "${RED}${message}${OFF}"
    exit 1
  fi
}

ensure_full_xcode() {
  require_tool xcode-select "xcode-select not found. Install Xcode."

  local selected="${DEVELOPER_DIR:-}"
  if [[ -z "$selected" ]]; then
    selected="$(xcode-select -p 2>/dev/null || true)"
  fi

  if [[ "$selected" == *".app/Contents/Developer" && -x "$selected/usr/bin/xcodebuild" ]]; then
    export DEVELOPER_DIR="$selected"
    return 0
  fi

  local candidate=""
  for app in /Applications/Xcode.app /Applications/Xcode*.app; do
    candidate="$app/Contents/Developer"
    if [[ -x "$candidate/usr/bin/xcodebuild" ]]; then
      export DEVELOPER_DIR="$candidate"
      echo -e "${YELLOW}Using Xcode at ${DEVELOPER_DIR}.${OFF}"
      return 0
    fi
  done

  echo -e "${RED}xcodebuild requires full Xcode, but the active developer directory is:${OFF}"
  echo "$selected"
  echo
  echo "Install Xcode from the App Store or set DEVELOPER_DIR to a full Xcode path, for example:"
  echo "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer script/build"
  exit 1
}

generate_xcodeproj() {
  if [[ ! -f "$DIR/project.yml" ]]; then
    echo -e "${YELLOW}project.yml not found; nothing to update.${OFF}"
    return 0
  fi

  require_tool xcodegen "xcodegen not found. Run script/bootstrap."
  mkdir -p "$DIR/.tmp"
  local lock_dir="$DIR/.tmp/xcodegen.lock"
  local waited=0
  until mkdir "$lock_dir" 2>/dev/null; do
    if (( waited == 0 )); then
      echo -e "${YELLOW}Waiting for existing XcodeGen run...${OFF}"
    fi
    sleep 0.2
    waited=$((waited + 1))
  done
  trap 'rm -rf "$lock_dir"' RETURN
  echo -e "${BLUE}Generating Xcode project...${OFF}"
  (cd "$DIR" && xcodegen generate)
  rm -rf "$lock_dir"
  trap - RETURN
  echo -e "${GREEN}Update complete!${OFF}"
}

find_project() {
  local project_path="${PROJECT_PATH:-}"

  if [[ -z "$project_path" ]]; then
    project_path=$(find "$DIR" -maxdepth 1 -name "*.xcodeproj" -print -quit)
  fi

  if [[ -z "$project_path" ]]; then
    echo -e "${RED}No .xcodeproj found. Run script/update.${OFF}"
    exit 1
  fi

  echo "$project_path"
}

set_xcodebuild_vars() {
  APP_NAME="${APP_NAME:-Espresso}"
  SCHEME="${SCHEME:-$APP_NAME}"
  CONFIGURATION="${CONFIGURATION:-Debug}"
  DERIVED_DATA="${DERIVED_DATA:-$DIR/build/DerivedData}"
}

has_swift_files() {
  find "$DIR" -name "*.swift" -print -quit | grep -q .
}
