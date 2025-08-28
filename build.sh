#!/bin/bash
set -e

# Paths
PROJECTS=~/projects
DISKS=~/coco-dev/disks
DRIVES=~/coco-dev/drives
CASSETTES=~/coco-dev/cassettes

# Usage
usage() {
  echo "Usage: $0 [-f] <project> <floppy|cassette|hard> [image_name]"
  exit 1
}

# Parse options
FORCE_CREATE=0
while getopts ":f" opt; do
  case $opt in
    f) FORCE_CREATE=1 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Args
PROJECT="$1"
TARGET_TYPE="$2"
IMAGE_NAME="$3"

if [ -z "$PROJECT" ] || [ -z "$TARGET_TYPE" ]; then
  usage
fi

# --- Selective TYPE merge (exact one-line replacements from types.b09) ---
SOURCE_PATH="$PROJECTS/$PROJECT/src/basic"
BUILD_PATH="$PROJECTS/$PROJECT/build/basic"

set -e
set -u

# Verbose mode toggle
VERBOSE=false

# === Preprocessing step: Transpile enhanced Basic09 using AWK ===

AWK_SCRIPT="$(dirname "$0")/gemini.awk"
GLOBAL_DEFS="$SOURCE_PATH/global.b09"

if [[ ! -f "$GLOBAL_DEFS" ]]; then
    echo "ERROR: Missing global definitions file: $GLOBAL_DEFS"
    exit 1
fi

if [[ ! -f "$AWK_SCRIPT" ]]; then
    echo "ERROR: Missing AWK transpiler script: $AWK_SCRIPT"
    exit 1
fi

echo "Transpiling enhanced Basic09 source files..."
files_processed=0

# Find all .b09 module files, excluding the global defs file itself
find "$SOURCE_PATH" -type f -name "*.b09" ! -name "global.b09" | while read -r src_file; do
    files_processed=$((files_processed+1))
    relative_path=$(realpath --relative-to="$SOURCE_PATH" "$src_file")
    dest_file="$BUILD_PATH/$relative_path"

    # Ensure the destination directory exists
    mkdir -p "$(dirname "$dest_file")"

    echo "  -> Transpiling $relative_path"

    # Run the awk script
    # Input: global.b09 and the current source file
    # Output: Redirected (>) to the destination file in the build directory
    awk -f "$AWK_SCRIPT" "$GLOBAL_DEFS" "$src_file" > "$dest_file"
done

echo "=== Preprocessing Summary ==="
echo "Files processed: $files_processed"

# Replace SOURCE_PATH with BUILD_PATH for rest of build
SOURCE_PATH="$BUILD_PATH"

# === Rest of your original build.sh logic continues here ===

case "$TARGET_TYPE" in
  floppy)
    IMAGE="$DISKS/${IMAGE_NAME}.dsk"
    CREATE_CMD="os9 format $IMAGE -ds -t80 -e -9"
    ATTR_CMD="os9 attr $IMAGE -ews"
    ;;
  cassette)
    IMAGE="$CASSETTES/${IMAGE_NAME}.cas"
    CREATE_CMD="cecb bulkerase -c $IMAGE"
    ATTR_CMD="os9 attr $IMAGE -ews"
    ;;
  hard)
    IMAGE="$DRIVES/${IMAGE_NAME}.vhd"
    CREATE_CMD="os9 format $IMAGE -bs256 -l40960 -e -n$PROJECT"
    ATTR_CMD="os9 attr $IMAGE -ews"
    ;;
  *)
    echo "Unknown target type: $TARGET_TYPE"
    usage
    ;;
esac

# Confirm or create image
if [ ! -f "$IMAGE" ]; then
  if [ "$FORCE_CREATE" -eq 1 ]; then
    echo "Creating image: $IMAGE"
    eval "$CREATE_CMD"
    echo "Setting image attributes: $IMAGE"
    eval "$ATTR_CMD"
  else
    read -p "Image $IMAGE not found. Create it? [y/N] " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "Creating image: $IMAGE"
      eval "$CREATE_CMD"
      echo "Setting image attributes: $IMAGE"
      eval "$ATTR_CMD"
    else
      echo "Aborted. Image required."
      exit 2
    fi
  fi
fi

# Validate image format by attempting listing (simple check)
if ! os9 dir "$IMAGE" >/dev/null 2>&1; then
  echo "Error: '$IMAGE' is not a valid OS-9 image."
  exit 3
fi

# Copy files
echo "Copying from $SOURCE_PATH to $IMAGE"
find "$SOURCE_PATH" -type f | while read file; do
  echo "  Copying $file"
  os9 copy -l -r "$file" "$IMAGE,${file#$SOURCE_PATH/}"
done

echo "✅ Build complete: $IMAGE"
