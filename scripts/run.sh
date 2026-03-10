#!/bin/bash
# One-command WhisperX subtitle generation and translation script

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

VIDEO_DIR="${VIDEO_DIR:-./videos}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
TRANSLATED_DIR="${TRANSLATED_DIR:-./translated}"
TARGET_LANG="${TARGET_LANG:-zh}"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  WhisperX Subtitle Generation + Translation Tool${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""

# Check dependencies
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ python3 not found${NC}"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}❌ ffmpeg not found (required by WhisperX)${NC}"
    echo "   Install with: brew install ffmpeg (macOS) or apt install ffmpeg (Linux)"
    exit 1
fi

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TRANSLATED_DIR"

# Step 1: transcription
echo -e "${YELLOW}🎬 Step 1: Transcribe video audio into subtitles${NC}"
echo ""

python3 "$SCRIPT_DIR/transcribe.py" "$VIDEO_DIR" -o "$OUTPUT_DIR" -m medium

echo ""
echo -e "${GREEN}✅ Transcription completed${NC}"
echo ""

# Step 2: translation (optional)
echo -e "${YELLOW}🌐 Step 2: Translate subtitles into target language ($TARGET_LANG)${NC}"
echo ""

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️ OPENAI_API_KEY is not set, skipping translation${NC}"
    echo "   To enable translation, run: export OPENAI_API_KEY=your_key"
    echo ""
else
    python3 "$SCRIPT_DIR/translate.py" "$OUTPUT_DIR" -o "$TRANSLATED_DIR" \
        -t "$TARGET_LANG" --bilingual --target-only
    echo ""
    echo -e "${GREEN}✅ Translation completed${NC}"
fi

echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  All tasks completed${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo "Output files:"
echo "  - Source subtitles:  $OUTPUT_DIR/*.{lang}.srt"
echo "  - Bilingual subtitles: $TRANSLATED_DIR/*.bilingual.srt"
echo "  - Target subtitles: $TRANSLATED_DIR/*.$TARGET_LANG.srt"
echo ""
