#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"

# --- Functions ---


list_reports() {
    echo "--- Available Encrypted Reports ---"
    ls -1 "$REPORTS_DIR"/*.asc 2>/dev/null | sed "s|$REPORTS_DIR/||" | nl

    if [ $? -ne 0 ]; then
        echo "No encrypted reports found in $REPORTS_DIR."
        return 1 # Indicate failure/no files found
    fi
    echo "-----------------------------------"
    return 0 # Indicate success/files listed
}
decrypt_report() {
    report_filename="$1"

    if [ ! -f "$REPORTS_DIR/$report_filename" ]; then
        echo "Error: File not found: $report_DIR/$report_filename" >&2
        return 1
    fi

    echo "--- Decrypting Report: $report_filename ---"

    # Use gpg to decrypt the file. GPG will automatically look for the private key
    # and prompt for a passphrase if needed.
    # --decrypt: perform decryption
    # --output -: send output to standard output
    decrypted_content=$(gpg --decrypt --output - "$REPORTS_DIR/$report_filename" 2>&1) # Capture output and stderr

    # Check the exit status of the gpg command
    if [ $? -eq 0 ]; then
        echo "Report decrypted successfully."
        echo "-----------------------------------"
        # Display the decrypted content
        echo "$decrypted_content"
        echo "-----------------------------------"
    else
        # Handle GPG decryption failure
        echo "Error: Failed to decrypt report '$report_filename'." >&2
        echo "This could be due to:" >&2
        echo "- The file is not a valid GPG encrypted file." >&2
        echo "- The correct private key is not available in your keyring." >&2
        echo "- The incorrect passphrase was entered." >&2
        echo "GPG output:" >&2
        echo "$decrypted_content" >&2 # Output GPG error messages
    fi

    echo "Press Enter to continue..."
    read -r # Wait for user to press Enter
}

# --- Main Program Logic ---

# Check if the reports directory exists
if [ ! -d "$REPORTS_DIR" ]; then
    echo "Error: Reports directory not found: $REPORTS_DIR" >&2
    echo "Please ensure the directory structure is correct." >&2
    exit 1
fi

# Main loop for decryption menu
while true; do
    clear
    echo "==============================================="
    echo "      HANTAM: Decryption Tool"
    echo "==============================================="

    list_reports # Show available reports

    # Check if list_reports function failed (no files)
    if [ $? -ne 0 ]; then
        echo "-----------------------------------"
        echo "No reports to decrypt. Exiting."
        echo "Press Enter to exit..."
        read -r
        exit 0
    fi

    echo "Enter the number or full filename of the report to decrypt (or 'q' to quit):"
    read -r selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        echo "Exiting decryption tool. Goodbye."
        exit 0
    fi


    REPORT_FILE=""
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        REPORT_FILE=$(ls -1 "$REPORTS_DIR"/*.asc 2>/dev/null | sed "s|$REPORTS_DIR/||" | nl | grep "^ *$selection\s" | sed "s|^ *$selection\s*||")
    else
        REPORT_FILE="$selection"
    fi

    if [ -n "$REPORT_FILE" ] && [ -f "$REPORTS_DIR/$REPORT_FILE" ] && [[ "$REPORT_FILE" == *.asc ]]; then
        decrypt_report "$REPORT_FILE"
    else
        echo "Invalid selection or file not found: '$selection'"
        echo "Press Enter to continue..."
        read -r
    fi
done
