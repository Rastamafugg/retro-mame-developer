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

# === Preprocessing step: Replace @@TYPE, @@CONST, @@VAR in src/basic/*.b09 ===

TYPES_FILE="$SOURCE_PATH/types.b09"
CONSTS_FILE="$SOURCE_PATH/constants.b09"
VARS_FILE="$SOURCE_PATH/variables.b09"

if [[ ! -f "$TYPES_FILE" ]]; then
    echo "ERROR: Missing $TYPES_FILE"
    exit 1
fi

if [[ ! -f "$CONSTS_FILE" ]]; then
    echo "ERROR: Missing $CONSTS_FILE"
    exit 1
fi

if [[ ! -f "$VARS_FILE" ]]; then
    echo "ERROR: Missing $VARS_FILE"
    exit 1
fi

# Load definitions into associative arrays
declare -A type_defs
declare -A const_defs
declare -A var_defs

# Read TYPE definitions
while IFS= read -r line; do
    if [[ "$line" =~ ^TYPE[[:space:]]+([^[:space:]]+)[[:space:]]*= ]]; then
        type_name="${BASH_REMATCH[1]}"
        type_defs["$type_name"]="$line"
    fi
done < <(tr -d '\r' < "$TYPES_FILE")

# Read CONST definitions
while IFS= read -r line; do
    if [[ "$line" =~ ^DIM[[:space:]]+([^[:space:]]+) ]]; then
        const_name="${BASH_REMATCH[1]}"
        const_defs["$const_name"]="$line"
    fi
done < <(tr -d '\r' < "$CONSTS_FILE")

# Read VAR definitions
while IFS= read -r line; do
    if [[ "$line" =~ ^DIM[[:space:]]+([^[:space:]]+) ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_defs["$var_name"]="$line"
    fi
done < <(tr -d '\r' < "$VARS_FILE")

files_processed=0
replacements_made=0
missing_defs=0

# Process source files
find "$SOURCE_PATH" -type f -name "*.b09" ! -name "types.b09" ! -name "constants.b09" ! -name "variables.b09" | while read -r src_file; do
    files_processed=$((files_processed+1))
    dest_file="$BUILD_PATH/$(realpath --relative-to="$SOURCE_PATH" "$src_file")"
    mkdir -p "$(dirname "$dest_file")"
    
    # Process line-by-line
    {
        tr -d '\r' < "$src_file" | while IFS= read -r line; do
            if [[ "$line" =~ ^([[:space:]]*)@@TYPE[[:space:]]+(.+)$ ]]; then
                indent="${BASH_REMATCH[1]}"
                type_name="${BASH_REMATCH[2]}"
                if [[ -n "${type_defs[$type_name]+x}" ]]; then
                    echo "${indent}${type_defs[$type_name]}"
                    replacements_made=$((replacements_made+1))
                    $VERBOSE && echo "Replaced TYPE $type_name in $src_file"
                else
                    echo "${indent}REM Missing TYPE definition for $type_name"
                    echo "ERROR: Missing TYPE definition for $type_name in $src_file"
                    missing_defs=$((missing_defs+1))
                fi
            elif [[ "$line" =~ ^([[:space:]]*)@@CONST[[:space:]]+(.+)$ ]]; then
                indent="${BASH_REMATCH[1]}"
                const_name="${BASH_REMATCH[2]}"
                if [[ -n "${const_defs[$const_name]+x}" ]]; then
                    echo "${indent}${const_defs[$const_name]}"
                    replacements_made=$((replacements_made+1))
                    $VERBOSE && echo "Replaced CONST $const_name in $src_file"
                else
                    echo "${indent}REM Missing CONST definition for $const_name"
                    echo "ERROR: Missing CONST definition for $const_name in $src_file"
                    missing_defs=$((missing_defs+1))
                fi
            elif [[ "$line" =~ ^([[:space:]]*)@@VAR[[:space:]]+(.+)$ ]]; then
                indent="${BASH_REMATCH[1]}"
                var_name="${BASH_REMATCH[2]}"
                if [[ -n "${var_defs[$var_name]+x}" ]]; then
                    echo "${indent}${var_defs[$var_name]}"
                    replacements_made=$((replacements_made+1))
                    $VERBOSE && echo "Replaced VAR $var_name in $src_file"
                else
                    echo "${indent}REM Missing VAR definition for $var_name"
                    echo "ERROR: Missing VAR definition for $var_name in $src_file"
                    missing_defs=$((missing_defs+1))
                fi                
            else
                echo "$line"
            fi
        done
    } > "$dest_file"
done

# Summary log
echo "=== Preprocessing Summary ==="
echo "Files processed: $files_processed"
echo "Replacements made: $replacements_made"
echo "Missing definitions: $missing_defs"

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
