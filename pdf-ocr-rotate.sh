#!/bin/bash

# Tool name
NAME="pdf-ocr-rotate"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 1. Dependency check ---
MISSING_DEPS=()
for dep in ocrmypdf tesseract-langpack-fra tesseract-osd; do
    if ! rpm -q "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}[X] Missing dependencies:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo -e "${YELLOW}Please run './install.sh' to install dependencies.${NC}"
    exit 1
fi

# --- 2. Argument validation ---
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $NAME <input.pdf> [output.pdf]"
    echo ""
    echo "  With one argument:  Process in-place (overwrites input file)"
    echo "  With two arguments: Create new output file"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$1}"  # If no second argument, output = input (in-place)
IN_PLACE=false

if [ "$#" -eq 1 ]; then
    IN_PLACE=true
fi

# Validate input file
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: File '$INPUT_FILE' does not exist.${NC}"
    exit 1
fi

if [[ "$INPUT_FILE" != *.pdf ]]; then
    echo -e "${RED}Error: Input file must have .pdf extension${NC}"
    exit 1
fi

# Validate output file
if [[ "$OUTPUT_FILE" != *.pdf ]]; then
    echo -e "${RED}Error: Output file must have .pdf extension${NC}"
    exit 1
fi

# --- 3. Warning (only if needed) ---
if [ "$IN_PLACE" = true ]; then
    echo -e "${YELLOW}[!] WARNING: The file will be overwritten after processing.${NC}"
    echo "File: $INPUT_FILE"
    echo ""
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
elif [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}[!] WARNING: Output file already exists and will be overwritten.${NC}"
    echo "File: $OUTPUT_FILE"
    echo ""
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# --- 4. Execution ---
echo -e "${GREEN}[*] Processing OCR and automatic rotation...${NC}"
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"

if [ "$IN_PLACE" = true ]; then
    # In-place: use temporary file
    TEMP_FILE=$(mktemp --suffix=.pdf)

    # Use threshold 0 to force rotation when misoriented text is detected
    ocrmypdf --rotate-pages --rotate-pages-threshold 0 -l fra "$INPUT_FILE" "$TEMP_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Replace original file
        mv "$TEMP_FILE" "$INPUT_FILE"
        echo -e "${GREEN}[V] Successfully completed!${NC}"
    else
        echo -e "${RED}[X] An error occurred during processing.${NC}"
        rm -f "$TEMP_FILE"
        exit 1
    fi
else
    # Output to different file
    ocrmypdf --rotate-pages --rotate-pages-threshold 0 -l fra "$INPUT_FILE" "$OUTPUT_FILE" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[V] Successfully completed!${NC}"
    else
        echo -e "${RED}[X] An error occurred during processing.${NC}"
        exit 1
    fi
fi
