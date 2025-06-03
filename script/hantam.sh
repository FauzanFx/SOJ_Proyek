#!/bin/bash

source "$(dirname "$0")/config.sh"

#Fungsi Validasi Tanggal
valid_date() {
    if [[ $1 =~ ^([0-9]{2}):([0-9]{2}):([0-9]{4})$ ]]; then
        day=${BASH_REMATCH[1]}
        month=${BASH_REMATCH[2]}
        year=${BASH_REMATCH[3]}
        if date -d "$year-$month-$day" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Fungsi Menu Utama
show_menu() {
    clear
    echo "===================================="
    echo "Hantam: Sistem Laporan Anonimus"
    echo "===================================="
    echo "1. Submit Laporan"
    echo "2. Decrypt Tool"
    echo "3. Exit"
    echo "===================================="
    read -p "Masukkan Pilihanmu: " choice
    case "$choice" in
        1) submit_report ;;
        2) show_menu_decrypt ;;
        3) echo "Terima kasih telah menggunakan Hantam." && exit 0 ;;
        *) echo "Pilihan tidak valid. Tekan Enter untuk mencoba lagi." && read -r && show_menu ;;
    esac
}

#Template Header Untuk Submit Report
template(){
    clear
    echo "--- Submit Laporan ---"
    echo "Anda akan diminta mengisi beberapa detail. Jawab sejujurnya."
    echo "JANGAN MEMASUKKAN INFORMASI PRIBADI."
    echo "-----------------------------------------------"
}

#Fungsi Submit Report
submit_report() {
    while true; do
        template
        read -p "Tanggal Kejadian (Format DD:MM:YYYY, Wajib): " tanggal_kejadian
        if [[ -z "$tanggal_kejadian" ]]; then
            echo "Input tanggal wajib diisi."
            read -r
        elif ! valid_date "$tanggal_kejadian"; then
            echo "Format salah atau tanggal tidak valid. Gunakan format DD:MM:YYYY."
            read -r
        else
            break
        fi
    done
    
    while true; do
        template
        read -p "Lokasi Kejadian (Wajib): " lokasi_kejadian
        if [[ -z "$lokasi_kejadian" ]]; then
            echo "Lokasi wajib diisi."
            read -r
        else
            break
        fi
    done

    declare -A unique
    tindakan_terpilih=()

    while true; do
        template
        echo "Kekerasan yang dialami:"
        echo "1. Fisik"
        echo "2. Verbal"
        echo "3. Non-Verbal"
        echo "4. Online"
        echo "5. Lainnya"
        echo "S. Selesai memilih"
        read -p "Pilihan Anda [1-5/S]: " pilihan

        case "$pilihan" in
            1) val="Fisik" ;;
            2) val="Verbal" ;;
            3) val="Non-Verbal" ;;
            4) val="Online" ;;
            5)
                read -p "Masukkan jenis lainnya: " lain
                val="Lainnya: ${lain:-[Tidak disebutkan]}"
                ;;
            s|S) break ;;
            *) echo "Pilihan tidak valid. Tekan Enter untuk lanjut..." ; read ; continue ;;
        esac

        if [[ -n "$val" && -z "${unique["$val"]}" ]]; then
            unique["$val"]=1
            tindakan_terpilih+=("$val")
            echo "Menambahkan: $val"
            read -r
        else
            echo "Pilihan sudah ada atau kosong."
            read -r -p "Tekan Enter untuk lanjut..."
        fi
    done

    echo ""
    echo "Tindakan terpilih:"
    for t in "${tindakan_terpilih[@]}"; do
        echo "- $t"
    done
    # Deskripsi
    template
    echo "Deskripsi Kronologis (Opsional):"
    echo "Tekan Enter dua kali untuk mengakhiri input."
    report_content=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        report_content+="$line\n"
    done

    # Proses Laporan
    TIMESTAMP=$(TZ=Asia/Jakarta date +"%Y-%m-%d %H:%M:%S WIB")
    if command -v uuidgen &> /dev/null; then
        REPORT_ID=$(uuidgen)
    else
        REPORT_ID=$(head -c 16 /dev/urandom | md5sum | cut -d' ' -f1)
    fi

    formatted_tindakan=""
    for item in "${tindakan_terpilih[@]}"; do
        formatted_tindakan+="- $item\n"
    done
    [ -z "$formatted_tindakan" ] && formatted_tindakan="[Tidak disebutkan]\n"

    formatted_report="Report ID: $REPORT_ID\n"
    formatted_report+="Timestamp: $TIMESTAMP\n"
    formatted_report+="===============================================\n\n"
    formatted_report+="Tanggal Kejadian: $tanggal_kejadian\n"
    formatted_report+="Lokasi Kejadian: $lokasi_kejadian\n\n"
    formatted_report+="Bentuk Tindak Pelecehan:\n${formatted_tindakan}\n"
    formatted_report+="-----------------------------------------------\n"
    formatted_report+="Deskripsi Kronologis:\n${report_content:-[Tidak diisi]}\n"

    echo "Mengenkripsi laporan..."
    encrypted_report=$(echo -e "$formatted_report" | gpg --encrypt --recipient "$GPG_RECIPIENT_KEY" --armor --output -)

    if [ $? -eq 0 ]; then
        REPORT_FILENAME="$REPORTS_DIR/${REPORT_ID}.asc"
        echo "$encrypted_report" > "$REPORT_FILENAME" && chmod 600 "$REPORT_FILENAME"
        touch "$REPORTS_DIR/${REPORT_ID}.status.undecrypted"
        echo "Laporan berhasil dikirim dan disimpan."
    else
        echo "Error: Gagal mengenkripsi laporan."
    fi

    echo "Tekan Enter untuk kembali ke menu utama..."
    read -r
    show_menu
}

#Menampilkan Daftar Laporan
daftar_laporan() {
    shopt -s nullglob
    files=("$REPORTS_DIR"/*.asc)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "Tidak ada laporan."
        return 1
    fi

    file_list=()
    i=1
    printf "%-4s %-35s %-20s %-15s\n" "No." "Nama File" "Tanggal Masuk" "Status"
    echo "---------------------------------------------------------------------"
    for file in "${files[@]}"; do
        filename="$(basename "$file")"
        base="${filename%.asc}"
        tanggal=$(stat -c %y "$file" | cut -d'.' -f1)
        status="[ ]"
        [ -f "$REPORTS_DIR/${base}.status.decrypted" ] && status="[*]"
        printf "%-4s %-35s %-20s %-15s\n" "$i." "$filename" "$tanggal" "$status"
        file_list+=("$filename")
        ((i++))
    done
    echo "---------------------------------------------------------------------"

    return 0
}

#Mendkripsi Laporan
dekripsi_laporan() {
    local nama_berkas="$1"
    if [ ! -f "$REPORTS_DIR/$nama_berkas" ]; then
        echo "File tidak ditemukan: $nama_berkas"
        return 1
    fi

    echo "Mendekripsi $nama_berkas..."
    hasil=$(gpg --decrypt --output - "$REPORTS_DIR/$nama_berkas" 2>&1)
    if [ $? -eq 0 ]; then
        echo "-------------------------------------------"
        echo -e "$hasil"
        echo "-------------------------------------------"
        base="${nama_berkas%.asc}"
        rm -f "$REPORTS_DIR/${base}.status.undecrypted"
        touch "$REPORTS_DIR/${base}.status.decrypted"
    else
        echo "Gagal dekripsi: $hasil"
    fi
    echo "Tekan Enter untuk melanjutkan..."
    read -r
}

#Menampilkan Menu Decrypt Tool
show_menu_decrypt() {
    while true; do
        clear
        echo "==============================================="
        echo "        HANTAM: Alat Dekripsi Laporan          "
        echo "==============================================="

        if ! daftar_laporan; then
            echo ""
            read -p "Tidak ada laporan yang ditemukan!" -r
            break 
        fi

        echo ""
        read -p "Masukkan nomor laporan yang ingin didekripsi (atau 'q' untuk kembali): " pilihan
        if [[ "$pilihan" == "q" || "$pilihan" == "Q" ]]; then
            break
        elif [[ "$pilihan" =~ ^[0-9]+$ ]] && (( pilihan >= 1 && pilihan <= ${#file_list[@]} )); then
            dekripsi_laporan "${file_list[$((pilihan-1))]}"
        else
            echo "Pilihan tidak valid." && read -p "Tekan Enter untuk lanjut..." -r
        fi
    done
    show_menu 
}

# Eksekusi awal
show_menu
