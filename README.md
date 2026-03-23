# pdf-utilities

Bash utilities for PDF manipulation on Fedora Linux:
- **pdf-ocr-rotate.sh**: OCR and automatic page rotation (in-place)
- **pdf-compress.sh**: PDF compression to screen quality (in-place)

## Installation

To install dependencies and scripts system-wide in `/usr/local/bin`:

```bash
sudo ./install.sh
```

This will:
1. Check and install required dependencies (ocrmypdf, tesseract, ghostscript)
2. Install the scripts to `/usr/local/bin`

After installation, the commands are available as:
- `pdf-ocr-rotate` (instead of `./pdf-ocr-rotate.sh`)
- `pdf-compress` (instead of `./pdf-compress.sh`)

To uninstall:
```bash
sudo ./uninstall.sh
```

## pdf-ocr-rotate.sh

Performs OCR (Optical Character Recognition) and automatic page rotation on PDF files using ocrmypdf.

### Usage
```bash
# Process in-place (overwrites input file)
./pdf-ocr-rotate.sh <input.pdf>

# Create new output file
./pdf-ocr-rotate.sh <input.pdf> <output.pdf>
```

⚠️ In-place mode overwrites the original file after confirmation. Output file mode only warns if the output file already exists.

## pdf-compress.sh

Compresses PDF files to `/screen` quality (72 dpi) using Ghostscript. Can process a single file or all PDFs in a folder.

### Usage
```bash
# Process file in-place (overwrites original)
./pdf-compress.sh document.pdf

# Create new output file
./pdf-compress.sh input.pdf output.pdf

# Process all PDFs in a folder (overwrites originals)
./pdf-compress.sh /path/to/folder
```

⚠️ In-place mode and folder mode overwrite files after confirmation. Output file mode only warns if the output file already exists.

## Requirements

All dependencies are installed by `install.sh`:
- ocrmypdf
- tesseract-langpack-fra
- tesseract-osd
- ghostscript

Scripts will fail with an error message if dependencies are missing.
