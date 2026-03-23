#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local/bin"
SCRIPTS=("pdf-ocr-rotate.sh" "pdf-compress.sh")
DEPENDENCIES=("ocrmypdf" "tesseract-langpack-fra" "tesseract-osd" "ghostscript")

echo -e "${GREEN}=== PDF Tools Installation ===${NC}"
echo ""

# Check that we are in the correct directory
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        echo -e "${RED}Error: Script '$script' not found in current directory.${NC}"
        echo "Please run this script from the directory containing the files to install."
        exit 1
    fi
done

# Check permissions (need sudo to install in /usr/local/bin)
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script requires sudo privileges to install in $INSTALL_DIR${NC}"
    echo "Restarting with sudo..."
    echo ""
    exec sudo "$0" "$@"
fi

# --- 1. Check and install dependencies ---
echo -e "${GREEN}[*] Checking dependencies...${NC}"

MISSING_DEPS=()
for dep in "${DEPENDENCIES[@]}"; do
    if ! rpm -q "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
        echo -e "${YELLOW}  [!] Missing: $dep${NC}"
    else
        echo -e "${GREEN}  [V] Installed: $dep${NC}"
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}The following packages need to be installed:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    read -p "Do you want to install these packages now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Installing dependencies...${NC}"
        dnf install -y "${MISSING_DEPS[@]}"
        if [ $? -ne 0 ]; then
            echo -e "${RED}[X] Failed to install dependencies.${NC}"
            exit 1
        fi
        echo -e "${GREEN}[V] Dependencies successfully installed.${NC}"
    else
        echo -e "${RED}Installation cancelled. Dependencies are required to use the tools.${NC}"
        exit 1
    fi
fi

echo ""

# --- 2. Install scripts ---
echo -e "${GREEN}[*] Installing to $INSTALL_DIR...${NC}"
for script in "${SCRIPTS[@]}"; do
    # Name without extension for installation
    NAME="${script%.sh}"

    echo "  - Installing $script → $INSTALL_DIR/$NAME"

    # Use install to copy and set permissions in one command
    install -m 755 "$script" "$INSTALL_DIR/$NAME"

    if [ $? -eq 0 ]; then
        echo -e "    ${GREEN}[V] Successfully installed${NC}"
    else
        echo -e "    ${RED}[X] Installation failed${NC}"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}=== Installation complete ===${NC}"
echo ""
echo "The following commands are now available:"
for script in "${SCRIPTS[@]}"; do
    NAME="${script%.sh}"
    echo "  - $NAME"
done
echo ""
echo "Usage examples:"
echo "  pdf-ocr-rotate <input.pdf>                    # Process in-place"
echo "  pdf-ocr-rotate <input.pdf> <output.pdf>       # Create new file"
echo "  pdf-compress <input.pdf>                      # Compress in-place"
echo "  pdf-compress <input.pdf> <output.pdf>         # Create new file"
echo "  pdf-compress <folder>                         # Compress all PDFs in folder"
echo ""
echo -e "${YELLOW}To uninstall, run: sudo ./uninstall.sh${NC}"
