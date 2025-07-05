#!/bin/bash
set -e

# --- Input arguments ---
echo "🔍 Parsing input arguments"
PROJECT_NAME="$1"
TARGET_TYPE="$2"  # floppy | cassette | hard
IMAGE_NAME="$3"   # optional override

# --- Validate input ---
echo "✅ Validating input arguments"
if [ -z "$PROJECT_NAME" ] || [ -z "$TARGET_TYPE" ]; then
  echo "Usage: $0 <project-name> <floppy|cassette|hard> [image-name]"
  exit 1
fi

PROJECT_ROOT="./$PROJECT_NAME"

# --- Create Directory Structure ---
echo "📁 Creating folder structure for '$PROJECT_NAME'"
mkdir -p "$PROJECT_ROOT"/{src/{basic,asm,img,snd,txt},docs,bin,log}

# --- Template Source Files ---
echo "📝 Creating BASIC template source file"
cat > "$PROJECT_ROOT/src/basic/main.bas" <<EOF
10 REM $PROJECT_NAME BASIC Template
20 PRINT "Hello from BASIC!"
30 END
EOF

echo "📝 Creating ASM template source file"
cat > "$PROJECT_ROOT/src/asm/main.asm" <<EOF
        org     \$C000
start   ldx     #msg
loop    lda     ,x+
        beq     done
        jsr     [charout]
        bra     loop
done    rts
msg     fcc     "Hello, World!"
        fcb     0
charout equ     \$A002
        end     start
EOF

# --- docs/README.md ---
echo "📄 Writing README.md"
cat > "$PROJECT_ROOT/docs/README.md" <<EOF
# $PROJECT_NAME

A new Color Computer project targeting output type: **$TARGET_TYPE**

## Project Structure

- \`src/basic\`: BASIC source
- \`src/asm\`: Assembly source
- \`src/img\`: Image assets
- \`src/snd\`: Sound/music
- \`src/txt\`: Text/data
- \`bin\`: Compiled output
- \`docs\`: Project documentation
- \`log\`: Build logs and diagnostics

## Build

Run:

\`\`\`bash
./build.sh
\`\`\`

Or invoke the master script with parameters.
EOF

# --- docs/LICENSE ---
echo "🪪 Writing MIT license"
cat > "$PROJECT_ROOT/docs/LICENSE" <<EOF
MIT License

Copyright (c) $(date +%Y)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
EOF

# --- .project_config ---
echo "🔧 Writing .project_config file"
cat > "$PROJECT_ROOT/.project_config" <<EOF
project: $PROJECT_NAME
target_type: $TARGET_TYPE
image_name: ${IMAGE_NAME:-<default>}
created: $(date -Iseconds)
EOF

# --- Makefile (Optional use) ---
echo "⚙️ Creating Makefile"
cat > "$PROJECT_ROOT/Makefile" <<EOF
# Makefile for $PROJECT_NAME

all:
	@echo "Use ./build.sh to build the project"

clean:
	rm -rf bin/*
EOF

# --- build.sh ---
echo "🚧 Writing build.sh wrapper"
cat > "$PROJECT_ROOT/build.sh" <<EOF
#!/bin/bash
set -e

# --- Project-specific variables ---
PROJECT_NAME="$PROJECT_NAME"
TARGET_TYPE="$TARGET_TYPE"
IMAGE_NAME="${IMAGE_NAME:-}"

# --- Script location awareness ---
SOURCE="\${BASH_SOURCE[0]}"
while [ -L "\$SOURCE" ]; do
  DIR="\$(cd -P "\$(dirname "\$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="\$(readlink "\$SOURCE")"
  [[ "\$SOURCE" != /* ]] && SOURCE="\$DIR/\$SOURCE"
done
SCRIPT_DIR="\$(cd -P "\$(dirname "\$SOURCE")" >/dev/null 2>&1 && pwd)"
cd "\$SCRIPT_DIR"

# --- Invoke root-level builder ---
echo "🚀 Running build script with: -f \"\$PROJECT_NAME\" \"\$TARGET_TYPE\" \"\$IMAGE_NAME\""
../build.sh -f "\$PROJECT_NAME" "\$TARGET_TYPE" "\$IMAGE_NAME"
EOF

chmod +x "$PROJECT_ROOT/build.sh"

echo "✅ Project '$PROJECT_NAME' created successfully."
