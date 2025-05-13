#!/bin/bash

# Setup script untuk HANTAM
echo "======================================"
echo               "HANTAM Setup"
echo "======================================"

# Cek dan install dependensi jika belum ada
install_if_missing() {
    if ! command -v "$1" &>/dev/null; then
        echo ">> '$1' tidak ditemukan. Mencoba menginstall..."
        sudo apt-get update
        sudo apt-get install -y "$1"
        if [ $? -ne 0 ]; then
            echo "Gagal menginstall $1. Harap install manual dan jalankan ulang setup." >&2
            exit 1
        fi
    else
        echo ">> '$1' sudah terpasang."
    fi
}

echo "[1/4] Mengecek dependensi..."
install_if_missing gpg
install_if_missing uuidgen
install_if_missing coreutils

echo "[2/4] Mengecek direktori report/..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"

mkdir -p "$REPORTS_DIR"
chmod 700 "$REPORTS_DIR"
echo ">> Direktori laporan: $REPORTS_DIR"

echo "[3/4] Memverifikasi kunci publik GPG penerima..."
GPG_KEY_ID="0624CF4C2CE76D2DBB419074B001B6FC013FB655"
if ! gpg --list-keys "$GPG_KEY_ID" &>/dev/null; then
    echo ">> Kunci GPG dengan ID $GPG_KEY_ID belum ada."
    echo "Apakah Anda ingin mengimpor kunci dari file atau dari keyserver? [file/server]"
    read -r choice
    if [[ "$choice" == "file" ]]; then
        echo "Masukkan path ke file public key (.asc):"
        read -r keyfile
        if [[ -f "$keyfile" ]]; then
            gpg --import "$keyfile"
        else
            echo "File tidak ditemukan. Setup dihentikan."
            exit 1
        fi
    elif [[ "$choice" == "server" ]]; then
        echo "Mengimpor kunci dari keyserver..."
        gpg --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY_ID"
    else
        echo "Pilihan tidak valid. Setup dihentikan."
        exit 1
    fi
else
    echo ">> Kunci GPG sudah ada."
fi

echo "[4/4] Setup selesai!"

# Menawarkan menjalankan hantam.sh
echo ""
echo "Apakah Anda ingin langsung menjalankan HANTAM sekarang? [y/n]"
read -r run_now

if [[ "$run_now" == "y" ]]; then
    echo "Menjalankan HANTAM..."
    chmod +x "script/hantam.sh"
    "script/hantam.sh"
else
    echo "Silakan jalankan 'hantam.sh' secara manual bila sudah siap."
fi
