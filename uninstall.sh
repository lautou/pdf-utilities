#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local/bin"
SCRIPTS=("pdf-ocr-rotate" "pdf-compress")

echo -e "${YELLOW}=== PDF Tools Uninstallation ===${NC}"
echo ""

# Check permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script requires sudo privileges to uninstall from $INSTALL_DIR${NC}"
    echo "Restarting with sudo..."
    echo ""
    exec sudo "$0" "$@"
fi

# Ask for confirmation
echo "The following files will be removed:"
for script in "${SCRIPTS[@]}"; do
    if [ -f "$INSTALL_DIR/$script" ]; then
        echo "  - $INSTALL_DIR/$script"
    fi
done
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Uninstall
echo -e "${GREEN}[*] Removing files...${NC}"
REMOVED=0
for script in "${SCRIPTS[@]}"; do
    if [ -f "$INSTALL_DIR/$script" ]; then
        echo "  - Removing $INSTALL_DIR/$script"
        rm -f "$INSTALL_DIR/$script"
        if [ $? -eq 0 ]; then
            echo -e "    ${GREEN}[V] Successfully removed${NC}"
            ((REMOVED++))
        else
            echo -e "    ${RED}[X] Removal failed${NC}"
        fi
    else
        echo "  - $INSTALL_DIR/$script does not exist (skipped)"
    fi
done

echo ""
if [ $REMOVED -gt 0 ]; then
    echo -e "${GREEN}=== Uninstallation complete ===${NC}"
    echo "$REMOVED file(s) removed."
else
    echo -e "${YELLOW}No files to uninstall.${NC}"
fi
