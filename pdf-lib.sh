#!/bin/bash

# Shared library for PDF utilities

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for missing RPM dependencies
# Usage: check_dependencies "dep1" "dep2" ...
check_dependencies() {
    local missing_deps=()
    for dep in "$@"; do
        if ! rpm -q "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}[X] Missing dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo -e "${YELLOW}Please run './install.sh' to install dependencies.${NC}"
        exit 1
    fi
}

# Validate arguments for PDF processing (1 or 2 args expected)
# Usage: validate_arguments "$#" "$NAME"
# Sets global: INPUT_FILE, OUTPUT_FILE, IN_PLACE
validate_arguments() {
    local arg_count=$1
    local tool_name=$2

    if [ "$arg_count" -lt 1 ] || [ "$arg_count" -gt 2 ]; then
        echo "Usage: $tool_name <input.pdf> [output.pdf]"
        echo ""
        echo "  With one argument:  Process in-place (overwrites input file)"
        echo "  With two arguments: Create new output file"
        exit 1
    fi
}

# Validate PDF files
# Usage: validate_files "$1" "$2"
# Sets global: INPUT_FILE, OUTPUT_FILE, IN_PLACE
validate_files() {
    INPUT_FILE="$1"
    OUTPUT_FILE="${2:-$1}"  # If no second argument, output = input (in-place)
    IN_PLACE=false

    if [ -z "$2" ]; then
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
}

# Show warning and prompt for confirmation
# Usage: prompt_overwrite_warning
# Requires global: IN_PLACE, INPUT_FILE, OUTPUT_FILE
prompt_overwrite_warning() {
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
}

# Execute a command on PDF with in-place support
# Usage: execute_pdf_command "Processing message" "command with {input} and {output} placeholders"
# Requires global: IN_PLACE, INPUT_FILE, OUTPUT_FILE
execute_pdf_command() {
    local message=$1
    local command_template=$2

    echo -e "${GREEN}[*] $message${NC}"
    echo "Input:  $INPUT_FILE"
    echo "Output: $OUTPUT_FILE"

    if [ "$IN_PLACE" = true ]; then
        # In-place: use temporary file
        local temp_file=$(mktemp --suffix=.pdf)

        # Replace placeholders in command with properly quoted filenames
        local command="${command_template//\{input\}/\"$INPUT_FILE\"}"
        command="${command//\{output\}/\"$temp_file\"}"

        # Execute command
        eval "$command" 2>/dev/null

        if [ $? -eq 0 ]; then
            # Replace original file
            mv "$temp_file" "$INPUT_FILE"
            echo -e "${GREEN}[V] Successfully completed!${NC}"
        else
            echo -e "${RED}[X] An error occurred during processing.${NC}"
            rm -f "$temp_file"
            exit 1
        fi
    else
        # Output to different file with properly quoted filenames
        local command="${command_template//\{input\}/\"$INPUT_FILE\"}"
        command="${command//\{output\}/\"$OUTPUT_FILE\"}"

        # Execute command
        eval "$command" 2>/dev/null

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[V] Successfully completed!${NC}"
        else
            echo -e "${RED}[X] An error occurred during processing.${NC}"
            exit 1
        fi
    fi
}
