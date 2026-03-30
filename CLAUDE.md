# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains three Bash utility scripts for PDF manipulation on Fedora Linux:
1. **pdf-ocr.sh**: Performs OCR only (in-place)
2. **pdf-ocr-rotate.sh**: Performs OCR and automatic page rotation (in-place)
3. **pdf-compress.sh**: Compresses PDFs to screen quality using Ghostscript (in-place)

A shared library (`pdf-lib.sh`) provides common functionality to avoid code duplication.
An installer script (`install.sh`) handles dependency installation and installs all tools to `/usr/local/bin`.

## Design Philosophy

**Separation of concerns:**
- **install.sh**: Handles all dependency management (checking and installing packages)
- **pdf-lib.sh**: Shared library providing common functions for dependency checking, validation, and execution
- **Runtime scripts**: Focus on their task, fail fast if dependencies are missing (no interactive installation)

**Code reuse:**
- Common functionality (dependency checking, file validation, warning prompts, in-place processing) is extracted to `pdf-lib.sh`
- Each script sources the library and calls functions with specific parameters
- Reduces code duplication while maintaining clarity

## System Requirements

- **Platform**: Fedora Linux (uses `dnf` package manager and `rpm` commands)

**All dependencies:**
- `ocrmypdf`: Core OCR processing tool (required by pdf-ocr.sh and pdf-ocr-rotate.sh)
- `tesseract-langpack-fra`: French language pack for Tesseract (required by pdf-ocr.sh and pdf-ocr-rotate.sh)
- `tesseract-osd`: Tesseract orientation and script detection (required by pdf-ocr-rotate.sh only)
- `ghostscript`: PDF processing and compression tool (required by pdf-compress.sh)

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

**OCR only:**
```bash
# Process in-place (overwrites input):
pdf-ocr <input.pdf>

# Create new output file:
pdf-ocr <input.pdf> <output.pdf>
```

**OCR with rotation:**
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

### pdf-lib.sh
- **Shared library**: Provides common functions for all PDF utilities
- **Functions**:
  - `check_dependencies`: Validates required RPM packages are installed
  - `validate_arguments`: Checks command-line argument count
  - `validate_files`: Validates input/output PDF files and determines in-place mode
  - `prompt_overwrite_warning`: Shows warnings and prompts for confirmation
  - `execute_pdf_command`: Executes commands with in-place support using temporary files
- **Sourcing**: Scripts look for the library in script directory (`.`) or `/usr/local/bin`
- **Template commands**: Uses `{input}` and `{output}` placeholders for flexible command execution

### pdf-ocr.sh
- **Flexible output**:
  - One argument: in-place (overwrites input after confirmation)
  - Two arguments: creates new output file (warns only if output exists)
- **Language**: OCR is configured for French (`-l fra` flag)
- **Dependency check**: Requires `ocrmypdf` and `tesseract-langpack-fra`
- **Safety**: Uses temporary files for in-place operations, only overwrites on success
- **Implementation**: Sources `pdf-lib.sh` and uses shared functions

### pdf-ocr-rotate.sh
- **Flexible output**:
  - One argument: in-place (overwrites input after confirmation)
  - Two arguments: creates new output file (warns only if output exists)
- **Language**: OCR is configured for French (`-l fra` flag)
- **Rotation threshold**: Set to 0 to force rotation whenever misoriented text is detected (`--rotate-pages-threshold 0`)
- **Dependency check**: Requires `ocrmypdf`, `tesseract-langpack-fra`, and `tesseract-osd`
- **Safety**: Uses temporary files for in-place operations, only overwrites on success
- **Implementation**: Sources `pdf-lib.sh` and uses shared functions

### pdf-compress.sh
- **Quality setting**: Uses `/screen` setting (72 dpi, smallest size, suitable for screen viewing)
- **Flexible output**:
  - One argument (file): in-place (overwrites input after confirmation)
  - Two arguments (both files): creates new output file (warns only if output exists)
  - One argument (folder): processes all PDFs in-place with single confirmation
- **Dependency check**: Requires `ghostscript` (uses shared library function)
- **Safety**: Uses temporary files for in-place operations, only overwrites on success
- **Error handling**: Continues processing remaining files if one fails, reports summary at the end
- **Implementation**: Sources `pdf-lib.sh` for dependency checking; has custom logic for folder processing

### Installer scripts
- **install.sh**:
  - Checks and installs all required dependencies (ocrmypdf, tesseract packages, ghostscript)
  - Installs shared library (`pdf-lib.sh`) with mode 644
  - Uses `install` command to copy scripts to `/usr/local/bin` with mode 755
  - Removes `.sh` extension from scripts for cleaner command names (library keeps extension)
  - Auto-elevates to sudo if needed
- **uninstall.sh**: Removes installed scripts and library from `/usr/local/bin` with confirmation prompt

## Testing the Scripts

To test manually:
```bash
# Make executable if needed
chmod +x pdf-ocr.sh
chmod +x pdf-ocr-rotate.sh
chmod +x pdf-compress.sh

# Test OCR only - in-place
cp original.pdf test.pdf
./pdf-ocr.sh test.pdf

# Test OCR only - new file
./pdf-ocr.sh original.pdf output.pdf

# Test OCR/rotation - in-place
cp original.pdf test2.pdf
./pdf-ocr-rotate.sh test2.pdf

# Test OCR/rotation - new file
./pdf-ocr-rotate.sh original.pdf output.pdf

# Test compression - in-place
cp original.pdf test3.pdf
./pdf-compress.sh test3.pdf

# Test compression - new file
./pdf-compress.sh original.pdf compressed.pdf
```

Note: If dependencies are missing, scripts will fail with an error message directing you to run `./install.sh`.
