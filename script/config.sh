#!/bin/bash

# ID Public Key GPG untuk enkripsi laporan
GPG_RECIPIENT_KEY="0624CF4C2CE76D2DBB419074B001B6FC013FB655"

# Direktori penyimpanan laporan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"

