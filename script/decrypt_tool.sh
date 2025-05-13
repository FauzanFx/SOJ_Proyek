#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"

# --- Fungsi-fungsi ---

daftar_laporan() {
    echo "--- Daftar Laporan Terenkripsi ---"
    
    shopt -s nullglob
    files=("$REPORTS_DIR"/*.asc)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "Tidak ada laporan terenkripsi di direktori $REPORTS_DIR."
        return 1
    fi

    file_list=() # Reset array
    i=1
    for file in "${files[@]}"; do
        echo "$i. $(basename "$file")"
        file_list+=("$(basename "$file")")
        ((i++))
    done

    echo "-----------------------------------"
    return 0
}



dekripsi_laporan() {
    nama_berkas="$1"

    if [ ! -f "$REPORTS_DIR/$nama_berkas" ]; then
        echo "Error: Berkas tidak ditemukan: $REPORTS_DIR/$nama_berkas" >&2
        return 1
    fi

    echo "--- Mendekripsi Laporan: $nama_berkas ---"

    isi_didekripsi=$(gpg --decrypt --output - "$REPORTS_DIR/$nama_berkas" 2>&1)

    if [ $? -eq 0 ]; then
        echo "Laporan berhasil didekripsi."
        echo "-----------------------------------"
        echo "$isi_didekripsi"
        echo "-----------------------------------"
    else
        echo "Error: Gagal mendekripsi laporan '$nama_berkas'." >&2
        echo "Kemungkinan penyebab:" >&2
        echo "- File bukan file terenkripsi GPG yang valid." >&2
        echo "- Kunci privat tidak tersedia di keyring Anda." >&2
        echo "- Passphrase yang dimasukkan salah." >&2
        echo "Pesan dari GPG:" >&2
        echo "$isi_didekripsi" >&2
    fi

    echo "Tekan Enter untuk melanjutkan..."
    read -r
}

# --- Program Utama ---

if [ ! -d "$REPORTS_DIR" ]; then
    echo "Error: Direktori laporan tidak ditemukan: $REPORTS_DIR" >&2
    echo "Pastikan struktur direktori sudah benar." >&2
    exit 1
fi

while true; do
    clear
    echo "==============================================="
    echo "        HANTAM: Alat Dekripsi Laporan"
    echo "==============================================="

    daftar_laporan

    if [ $? -ne 0 ]; then
        echo "-----------------------------------"
        echo "Tidak ada laporan untuk didekripsi."
        echo "Tekan Enter untuk keluar..."
        read -r
        exit 0
    fi

    echo "Masukkan nama lengkap laporan yang ingin didekripsi (atau 'q' untuk keluar):"
    read -r pilihan

    if [[ "$pilihan" == "q" || "$pilihan" == "Q" ]]; then
        echo "Keluar dari alat dekripsi. Sampai jumpa."
        exit 0
    fi

    BERKAS_LAPORAN=""
    if [[ "$pilihan" =~ ^[0-9]+$ ]]; then
        BERKAS_LAPORAN=$(ls -1 "$REPORTS_DIR"/*.asc 2>/dev/null | sed "s|$REPORTS_DIR/||" | nl | grep "^ *$pilihan\s" | sed "s|^ *$pilihan\s*||")
    else
        BERKAS_LAPORAN="$pilihan"
    fi

    if [ -n "$BERKAS_LAPORAN" ] && [ -f "$REPORTS_DIR/$BERKAS_LAPORAN" ] && [[ "$BERKAS_LAPORAN" == *.asc ]]; then
        dekripsi_laporan "$BERKAS_LAPORAN"
    else
        echo "Pilihan tidak valid atau file tidak ditemukan: '$pilihan'"
        echo "Tekan Enter untuk melanjutkan..."
        read -r
    fi
done
