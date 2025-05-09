#!/bin/bash

# ==============================================================================
# HANTAM: Anonymous Reporting System - Decryption Script (Revised)
# ==============================================================================
# This script is for authorized personnel to decrypt and read submitted reports.
# It requires access to the private GPG key corresponding to the public key
# used for encryption in the hantam.sh script.
#
# IMPORTANT: Set strict file permissions on this script! (chmod 700 decrypt_reports.sh)
#
# Author: Your Name/Alias (Optional)
# Date: May 9, 2025 (Update this date)
# Version: 0.4 (Fixed local keyword usage in main loop)
# ==============================================================================

# --- Configuration ---
# Define the base directory where encrypted reports are stored.
# This should match the 'report' directory used in hantam.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")" # Assumes scripts/ is directly inside BASE_DIR
REPORTS_DIR="$BASE_DIR/report"     # Assumes 'report' is the reports directory name

# --- Functions ---

# Function to list available reports and return filenames (null-separated)
# This function finds files ending in .asc in the reports directory
# and outputs their full paths separated by null characters.
list_report_filenames() {
    # Use find for robustness, handling spaces and special characters in filenames.
    # -maxdepth 1: only look in the reports directory itself, not subdirectories.
    # -name "*.asc": find files ending with .asc.
    # -print0: print the full file path followed by a null character.
    find "$REPORTS_DIR" -maxdepth 1 -name "*.asc" -print0
}

# Function to decrypt and display a selected report
# Takes the full file path of the encrypted report as an argument.
decrypt_report() {
    local report_filepath="$1" # Get the full filepath passed as argument

    # Check if the specified file exists.
    if [ ! -f "$report_filepath" ]; then
        echo "Error: File not found: $report_filepath" >&2
        return 1 # Indicate error
    fi

    # Display the filename being decrypted (using basename to show just the name).
    echo "--- Decrypting Report: $(basename "$report_filepath") ---"

    # Use gpg to decrypt the file.
    # GPG automatically looks for the corresponding private key in the user's keyring.
    # It will prompt for a passphrase if the private key is protected.
    # --decrypt: perform the decryption operation.
    # --output -: send the decrypted output to standard output.
    # 2>&1: Redirect standard error (where GPG might print prompts or errors) to standard output,
    # so it's captured by the $(...) command substitution.
    decrypted_content=$(gpg --decrypt --output - "$report_filepath" 2>&1)

    # Check the exit status of the gpg command.
    if [ $? -eq 0 ]; then
        echo "Report decrypted successfully."
        echo "-----------------------------------"
        # Display the decrypted content.
        echo "$decrypted_content"
        echo "-----------------------------------"
    else
        # Handle GPG decryption failure.
        echo "Error: Failed to decrypt report '$(basename "$report_filepath")'." >&2
        echo "This could be due to:" >&2
        echo "- The file is not a valid GPG encrypted file." >&2
        echo "- The correct private key is not available in your keyring." >&2
        echo "- The incorrect passphrase was entered." >&2

        # Output GPG error messages if captured.
        # Simple check: if captured content is relatively short, assume it's an error message.
        if [[ ${#decrypted_content} -lt 500 ]]; then
            echo "GPG output:" >&2
            echo "$decrypted_content" >&2 # Output captured GPG error messages
        else
            # If the captured content is long, it might be partially decrypted data
            # mixed with an error, or just a long error message.
            echo "GPG output was lengthy. Check GPG logs or run gpg command manually for detailed error." >&2
        fi
    fi

    echo "Press Enter to continue..."
    read -r # Wait for user to press Enter before returning to the menu.
}

# --- Main Program Logic ---

# Check if the reports directory exists.
if [ ! -d "$REPORTS_DIR" ]; then
    echo "Error: Reports directory not found: $REPORTS_DIR" >&2
    echo "Please ensure the directory structure is correct and the 'report' folder exists." >&2
    exit 1 # Exit the script if the reports directory is missing.
fi

# Main loop for the decryption menu.
while true; do
    clear # Clear the screen for a clean menu display.
    echo "==============================================="
    echo "      HANTAM: Decryption Tool"
    echo "==============================================="

    # Populate the report_files array with full paths from the reports directory.
    # This array will be used to list and select reports by number.
    report_files=() # Initialize an empty array for this iteration of the loop.

    # Read the null-separated filenames from the list_report_filenames function's output
    # into the report_files array.
    while IFS= read -r -d $'\0' filename; do
        report_files+=("$filename") # Add the full file path to the array.
    done < <(list_report_filenames) # Execute the function and pipe its output to the while loop.

    # REMOVED 'local' keyword - line 117 in previous version
    num_reports=${#report_files[@]} # Get the number of reports found (array size).

    # Check if any reports were found.
    if [ "$num_reports" -eq 0 ]; then
        echo "-----------------------------------"
        echo "No encrypted reports found in $REPORTS_DIR."
        echo "-----------------------------------"
        echo "No reports to decrypt. Exiting."
        echo "Press Enter to exit..."
        read -r # Wait for user input before exiting.
        exit 0 # Exit the script.
    fi

    # Display the available reports with numbers.
    echo "--- Available Encrypted Reports ---"
    # Loop through the array indices to display reports with 1-based numbering.
    for i in "${!report_files[@]}"; do
        # Print the number (index + 1) and the filename (using basename).
        echo "  $((i + 1)). $(basename "${report_files[$i]}")"
    done
    echo "-----------------------------------"

    # Prompt the user to select a report or quit.
    echo "Enter the number of the report to decrypt (1-$num_reports, or 'q' to quit):"
    read -r selection # Read the user's input.

    # Check if the user wants to quit.
    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        echo "Exiting decryption tool. Goodbye."
        exit 0 # Exit the script.
    fi

    # Validate the user's selection.
    # Check if the input is a number, is at least 1, and is not greater than the number of reports.
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$num_reports" ]; then
        # User entered a valid number.
        # Calculate the 0-based array index from the user's 1-based selection.
        # REMOVED 'local' keyword - line 130 in previous version
        selected_index=$((selection - 1))
        # Get the full file path of the selected report from the array.
        # REMOVED 'local' keyword - line 132 in previous version
        selected_filepath="${report_files[$selected_index]}"

        # Call the decrypt function with the full file path.
        decrypt_report "$selected_filepath"

    else
        # Handle invalid input (not a number, or out of range).
        echo "Invalid selection. Please enter a number between 1 and $num_reports, or 'q'." >&2 # Print error to stderr.
        echo "Press Enter to continue..."
        read -r # Wait for user input before showing the menu again.
    fi
done # End of the main while loop.

# Note: The script exits from within the loop using 'exit 0' or 'exit 1'.
# Code placed after this loop would only be reached if the loop somehow terminated
# without an explicit exit, which is not expected in this design.
