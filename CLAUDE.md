# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains two Bash utility scripts for PDF manipulation on Fedora Linux:
1. **pdf-ocr-rotate.sh**: Performs OCR and automatic page rotation (in-place)
2. **pdf-compress.sh**: Compresses PDFs to screen quality using Ghostscript (in-place)

An installer script (`install.sh`) handles dependency installation and installs both tools to `/usr/local/bin`.

## Design Philosophy

**Separation of concerns:**
- **install.sh**: Handles all dependency management (checking and installing packages)
- **Runtime scripts**: Focus on their task, fail fast if dependencies are missing (no interactive installation)

## System Requirements

- **Platform**: Fedora Linux (uses `dnf` package manager and `rpm` commands)

**All dependencies:**
- `ocrmypdf`: Core OCR processing tool
- `tesseract-langpack-fra`: French language pack for Tesseract
- `tesseract-osd`: Tesseract orientation and script detection
- `ghostscript`: PDF processing and compression tool

Dependencies are managed by `install.sh`. Runtime scripts check for dependencies and fail if missing.

## Installation

Install both scripts system-wide:
```bash
sudo ./install.sh
```

Uninstall:
```bash
sudo ./uninstall.sh
```

## Usage

**OCR and rotation:**
```bash
# Process in-place (overwrites input):
pdf-ocr-rotate <input.pdf>

# Create new output file:
pdf-ocr-rotate <input.pdf> <output.pdf>
```

**Compression:**
```bash
# Process file in-place (overwrites input):
pdf-compress <input.pdf>

# Create new output file:
pdf-compress <input.pdf> <output.pdf>

# Process all PDFs in folder (in-place):
pdf-compress /path/to/folder
```

Add `./` prefix when running directly from repository (e.g., `./pdf-ocr-rotate.sh`).

**Warning behavior:**
- In-place mode: Always warns before overwriting
- Output file mode: Only warns if output file already exists
- Folder mode: Always warns, shows list of files to be overwritten

## Key Implementation Details

### pdf-ocr-rotate.sh
- **Flexible output**:
  - One argument: in-place (overwrites input after confirmation)
  - Two arguments: creates new output file (warns only if output exists)
- **Language**: OCR is configured for French (`-l fra` flag)
- **Rotation threshold**: Set to 0 to force rotation whenever misoriented text is detected (`--rotate-pages-threshold 0`)
- **Dependency check**: Fails fast if dependencies are missing (no interactive installation)
- **Safety**: Uses temporary files for in-place operations, only overwrites on success

### pdf-compress.sh
- **Quality setting**: Uses `/screen` setting (72 dpi, smallest size, suitable for screen viewing)
- **Flexible output**:
  - One argument (file): in-place (overwrites input after confirmation)
  - Two arguments (both files): creates new output file (warns only if output exists)
  - One argument (folder): processes all PDFs in-place with single confirmation
- **Dependency check**: Fails fast if dependencies are missing (no interactive installation)
- **Safety**: Uses temporary files for in-place operations, only overwrites on success
- **Error handling**: Continues processing remaining files if one fails, reports summary at the end

### Installer scripts
- **install.sh**:
  - Checks and installs all required dependencies (ocrmypdf, tesseract packages, ghostscript)
  - Uses `install` command to copy scripts to `/usr/local/bin` with mode 755
  - Removes `.sh` extension for cleaner command names
  - Auto-elevates to sudo if needed
- **uninstall.sh**: Removes installed scripts from `/usr/local/bin` with confirmation prompt

## Testing the Scripts

To test manually:
```bash
# Make executable if needed
chmod +x pdf-ocr-rotate.sh
chmod +x pdf-compress.sh

# Test OCR/rotation - in-place
cp original.pdf test.pdf
./pdf-ocr-rotate.sh test.pdf

# Test OCR/rotation - new file
./pdf-ocr-rotate.sh original.pdf output.pdf

# Test compression - in-place
cp original.pdf test2.pdf
./pdf-compress.sh test2.pdf

# Test compression - new file
./pdf-compress.sh original.pdf compressed.pdf
```

Note: If dependencies are missing, scripts will fail with an error message directing you to run `./install.sh`.
