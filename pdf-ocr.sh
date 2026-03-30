#!/bin/bash

# Tool name
NAME="pdf-ocr"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared library
if [ -f "$SCRIPT_DIR/pdf-lib.sh" ]; then
    source "$SCRIPT_DIR/pdf-lib.sh"
elif [ -f "/usr/local/bin/pdf-lib.sh" ]; then
    source "/usr/local/bin/pdf-lib.sh"
else
    echo "Error: pdf-lib.sh not found"
    exit 1
fi

# Check dependencies
check_dependencies "ocrmypdf" "tesseract-langpack-fra"

# Validate arguments
validate_arguments "$#" "$NAME"

# Validate files
validate_files "$1" "$2"

# Prompt for confirmation if needed
prompt_overwrite_warning

# Execute OCR command
execute_pdf_command "Processing OCR..." "ocrmypdf -l fra {input} {output}"
