#!/bin/bash

# ==============================================================================
# HANTAM: Anonymous Reporting System - Setup Script
# ==============================================================================
# This script sets up the basic folder structure and checks for necessary dependencies.
# It also guides the user through importing the GPG public key.
#
# ==============================================================================

# Define the base directory name
BASE_DIR="Hantams"

# Define the subdirectories
SCRIPTS_DIR="$BASE_DIR/scripts"
REPORTS_DIR="$BASE_DIR/report"

# --- Dependency Checks ---

echo "Checking for required dependencies..."

# Check for GPG
if ! command -v gpg &> /dev/null; then
    echo "Error: GPG (GNU Privacy Guard) is not installed." >&2
    echo "Please install GPG. On Debian/Ubuntu, run: sudo apt update && sudo apt install gnupg" >&2
    echo "On Fedora/CentOS/RHEL, run: sudo yum install gnupg2" >&2 # Use gnupg2 for newer systems
    echo "Please install GPG and run this setup script again." >&2
    exit 1
else
    echo "GPG found."
	gpg --armor -import-secret-keys "0624CF4C2CE76D2DBB419074B001B6FC013FB655"> recipient_secret_key.asc
fi

# Check for uuidgen (optional, as we have a fallback, but good to recommend)
if ! command -v uuidgen &> /dev/null; then
    echo "Warning: uuidgen not found. The script will use a fallback for generating IDs." >&2
    # Instructions for installing uuidgen if desired
    # On Debian/Ubuntu: sudo apt install uuid-runtime
    # On Fedora/CentOS/RHEL: sudo yum install uuid
fi

echo "Dependency checks complete."
# --- Folder Structure Creation ---

echo "Creating directory structure for HANTAM..."

# ... (rest of your existing mkdir and check code for BASE_DIR, SCRIPTS_DIR, REPORTS_DIR) ...

echo "Folder structure setup complete."
echo "Base directory: $(realpath $BASE_DIR)"
echo "Scripts directory: $(realpath $SCRIPTS_DIR)"
echo "Reports directory: $(realpath $REPORTS_DIR)"

# --- README Comment ---
# ... (keep your README comment block) ...
