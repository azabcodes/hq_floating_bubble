#!/bin/bash
# Script: chmod +x scripts/collect_kotlin.sh && ./scripts/collect_kotlin.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KOTLIN_DIR="$PROJECT_ROOT/android/src/main/kotlin"
OUTPUT_FILE="$PROJECT_ROOT/kotlin_dump.txt"

if [ ! -d "$KOTLIN_DIR" ]; then
  echo "❌ Directory not found: $KOTLIN_DIR"
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
  REL_PATH="${FILE#$KOTLIN_DIR/}"
  COUNT=$((COUNT + 1))

  echo "########################################" >> "$OUTPUT_FILE"
  echo "# FILE: $REL_PATH" >> "$OUTPUT_FILE"
  echo "########################################" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$FILE" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

done < <(find "$KOTLIN_DIR" -name "*.kt" -type f -print0 | sort -z)

echo "=============================" >> "$OUTPUT_FILE"
echo "  Total Files: $COUNT" >> "$OUTPUT_FILE"
echo "=============================" >> "$OUTPUT_FILE"

echo "✅ Success! Collected $COUNT Kotlin files"
echo "📄 File: $OUTPUT_FILE"
