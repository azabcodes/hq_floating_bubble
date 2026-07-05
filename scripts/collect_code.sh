#!/bin/bash
# Script: chmod +x scripts/collect_code.sh && ./scripts/collect_code.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CODE_DIR="$PROJECT_ROOT/example/lib"
OUTPUT_FILE="$PROJECT_ROOT/code_dump.txt"

if [ ! -d "$CODE_DIR" ]; then
  echo "❌ Directory not found: $CODE_DIR"
  exit 1
fi

> "$OUTPUT_FILE"

echo "=============================" >> "$OUTPUT_FILE"
echo "  Kotlin files collection" >> "$OUTPUT_FILE"
echo "  $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "=============================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

COUNT=0

while IFS= read -r -d '' FILE; do
  REL_PATH="${FILE#$CODE_DIR/}"
  COUNT=$((COUNT + 1))

  echo "########################################" >> "$OUTPUT_FILE"
  echo "# FILE: $REL_PATH" >> "$OUTPUT_FILE"
  echo "########################################" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$FILE" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

done < <(find "$CODE_DIR" -name "*.dart" -type f -print0 | sort -z)

echo "=============================" >> "$OUTPUT_FILE"
echo "  Total Files: $COUNT" >> "$OUTPUT_FILE"
echo "=============================" >> "$OUTPUT_FILE"

echo "✅ Success! Collected $COUNT code files"
echo "📄 File: $OUTPUT_FILE"
