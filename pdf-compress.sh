#!/bin/bash

# Tool name
NAME="pdf-compress"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 1. Dependency check ---
if ! rpm -q ghostscript &> /dev/null; then
    echo -e "${RED}[X] Missing dependency: ghostscript${NC}"
    echo ""
    echo -e "${YELLOW}Please run './install.sh' to install dependencies.${NC}"
    exit 1
fi

# --- 2. Argument validation ---
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $NAME <input.pdf|folder> [output.pdf]"
    echo ""
    echo "  With one argument (file):   Process in-place (overwrites input file)"
    echo "  With one argument (folder): Process all PDFs in-place"
    echo "  With two arguments:         Create new output file (folder not allowed)"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-}"

if [ ! -e "$INPUT" ]; then
    echo -e "${RED}Error: '$INPUT' does not exist.${NC}"
    exit 1
fi

# --- 3. Determine mode ---
IN_PLACE=false
IS_FOLDER=false

if [ -d "$INPUT" ]; then
    # Folder mode
    if [ -n "$OUTPUT" ]; then
        echo -e "${RED}Error: Output file cannot be specified when input is a folder.${NC}"
        exit 1
    fi
    IS_FOLDER=true
    IN_PLACE=true
elif [ -f "$INPUT" ]; then
    # File mode
    if [[ "$INPUT" != *.pdf ]]; then
        echo -e "${RED}Error: Input file must have .pdf extension${NC}"
        exit 1
    fi

    if [ -z "$OUTPUT" ]; then
        # In-place
        IN_PLACE=true
        OUTPUT="$INPUT"
    else
        # Output to different file
        if [[ "$OUTPUT" != *.pdf ]]; then
            echo -e "${RED}Error: Output file must have .pdf extension${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}Error: '$INPUT' is neither a file nor a folder.${NC}"
    exit 1
fi

# --- 4. Build file list ---
PDF_FILES=()

if [ "$IS_FOLDER" = true ]; then
    while IFS= read -r -d '' file; do
        PDF_FILES+=("$file")
    done < <(find "$INPUT" -maxdepth 1 -type f -name "*.pdf" -print0)

    if [ ${#PDF_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No PDF files found in '$INPUT'${NC}"
        exit 0
    fi
else
    PDF_FILES+=("$INPUT")
fi

# --- 5. Warning (only if needed) ---
if [ "$IN_PLACE" = true ]; then
    if [ "$IS_FOLDER" = true ]; then
        echo -e "${YELLOW}[!] WARNING: This operation will overwrite the following files:${NC}"
        for pdf in "${PDF_FILES[@]}"; do
            echo "  - $pdf"
        done
        echo ""
        echo -e "${YELLOW}Original files will be replaced with compressed versions (/screen quality).${NC}"
    else
        echo -e "${YELLOW}[!] WARNING: The file will be overwritten after processing.${NC}"
        echo "File: $INPUT"
        echo ""
    fi
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
elif [ -f "$OUTPUT" ]; then
    echo -e "${YELLOW}[!] WARNING: Output file already exists and will be overwritten.${NC}"
    echo "File: $OUTPUT"
    echo ""
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# --- 6. Process files ---
echo -e "${GREEN}[*] Compressing PDFs...${NC}"

PROCESSED=0
FAILED=0

if [ "$IS_FOLDER" = false ] && [ "$IN_PLACE" = false ]; then
    # Single file to different output
    echo "Input:  $INPUT"
    echo "Output: $OUTPUT"

    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/screen \
       -dNOPAUSE \
       -dQUIET \
       -dBATCH \
       -sOutputFile="$OUTPUT" \
       "$INPUT" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[V] Successfully compressed!${NC}"
    else
        echo -e "${RED}[X] Compression failed${NC}"
        exit 1
    fi
else
    # In-place processing (single file or folder)
    for pdf in "${PDF_FILES[@]}"; do
        echo -e "${GREEN}[*] Processing: $pdf${NC}"

        # Create temporary file
        TEMP_FILE=$(mktemp --suffix=.pdf)

        # Compress with Ghostscript
        gs -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.4 \
           -dPDFSETTINGS=/screen \
           -dNOPAUSE \
           -dQUIET \
           -dBATCH \
           -sOutputFile="$TEMP_FILE" \
           "$pdf" 2>/dev/null

        if [ $? -eq 0 ]; then
            # Replace original file
            mv "$TEMP_FILE" "$pdf"
            echo -e "${GREEN}  [V] Successfully compressed${NC}"
            ((PROCESSED++))
        else
            echo -e "${RED}  [X] Compression failed${NC}"
            rm -f "$TEMP_FILE"
            ((FAILED++))
        fi
    done

    # Summary
    if [ ${#PDF_FILES[@]} -gt 1 ] || [ "$IS_FOLDER" = true ]; then
        echo ""
        echo -e "${GREEN}[*] Processing complete:${NC}"
        echo "  - Files compressed: $PROCESSED"
        if [ $FAILED -gt 0 ]; then
            echo -e "  - ${RED}Failures: $FAILED${NC}"
        fi
    fi
fi
