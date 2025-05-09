#!/bin/bash

# Anonymou
# Definisi dari direktori
BASE_DIR="Hantams"

# Definisi dari sub-direktori
SCRIPT_DIR="$BASE_DIR/script"
REPORT_DIR="$BASE_DIR/report"

echo "Creating the directory structure..."

# Membuat direktori base apabila belum dibuat
if [ ! -d "$BASE_DIR" ]; then
    mkdir "$BASE_DIR"
    echo "$BASE_DIR created..."
else
    echo "$BASE_DIR already exists"
fi

# Membuat direktori script apabila belum dibuat
if [ ! -d "$SCRIPT_DIR" ]; then
    mkdir "$SCRIPT_DIR"
    echo "$SCRIPT_DIR created..."
else
    echo "$SCRIPT_DIR already exists"
fi

if [ ! -d "$REPORT_DIR" ]; then
    mkdir "$REPORT_DIR"
    echo "$REPORT_DIR created..."
else
    echo "$REPORT_DIR already exists"
fi

echo "Folder structure complete"
echo "Base directory: $(realpath "$BASE_DIR")"
echo "Script directory: $(realpath "$SCRIPT_DIR")"
echo "Report directory: $(realpath "$REPORT_DIR")"

