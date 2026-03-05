#!/bin/bash
set -e

# --- Project-specific variables ---
PROJECT_NAME="stocksAndBonds"
TARGET_TYPE="floppy"
IMAGE_NAME="snb"

# --- Script location awareness ---
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPT_DIR"

# --- Invoke root-level builder ---
echo "🚀 Running build script with: -f \"$PROJECT_NAME\" \"$TARGET_TYPE\" \"$IMAGE_NAME\""
../build.sh -f "$PROJECT_NAME" "$TARGET_TYPE" "$IMAGE_NAME"
