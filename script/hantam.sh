#!/bin/bash

source "$(dirname "$0")/config.sh"
#Fungsi-fungsi
show_menu(){
	clear
	echo "===================================="
	echo "Hantam: Sistem Laporan Anonimus	"
	echo "===================================="
	echo "1. Submit Laporan"
	echo "2. Decrypt Tool"
	echo "3. Exit"
	echo "===================================="
	echo "Enter your Choice:"
}
submit_report(){
	echo "--- Submit Laporan ---"
	echo "Deskripsikan kekerasan seksual yang anda alami"
    	echo "Berikan detail mengenai waktu dan tempat kejadian."
    	echo "JANGAN MEMASUKKAN INFORMASI PRIBADI YANG DAPAT MENGIDENTIFIKASI DIRI ANDA ATAUPUN ORANG LAIN."
    	echo "Tekan Enter sebanyak 2 kali apabila sudah selesai."
    	echo "-----------------------------------------------"

    	report_content=""

    	while IFS= read -r line; do
        	if [[ -z "$line" ]]; then
            		break
        	fi

        	report_content+="$(printf "%s\\n" "$line")"
    	done
	TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    	# Membuat ID Random dan Unik
    	if command -v uuidgen &> /dev/null; then
        	REPORT_ID=$(uuidgen)
    	else

        	REPORT_ID=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' ' | md5sum | head -c 32)
        	echo "Warning: uuidgen not found. Using a fallback method to generate ID." >&2
	fi

    	formatted_report="Report ID: $REPORT_ID\nTimestamp: $TIMESTAMP\n-----------------------------------------------\n$report_content"

	 echo "Mengenkripsi laporan..."

    encrypted_report=$(echo -e "$formatted_report" | gpg --encrypt --recipient "$GPG_RECIPIENT_KEY" --armor --output -)

    if [ $? -eq 0 ]; then
        echo "Laporan berhasil dienkripsi."
        REPORT_FILENAME="$REPORTS_DIR/${REPORT_ID}.asc"
        echo "Menyimpan laporan terenkripsi ke $REPORT_FILENAME ..."
        echo "$encrypted_report" > "$REPORT_FILENAME"
        if [ $? -eq 0 ]; then
            echo "Laporan berhasil disimpan."
            chmod 600 "$REPORT_FILENAME" 
            echo "Izin diatur untuk $REPORT_FILENAME."
            echo "-----------------------------------------------"
            echo "Laporan berhasil dikirim dan disimpan dengan aman."
            echo "Terima kasih atas keberanian Anda."
            echo "-----------------------------------------------"
	else
            echo "Error: Gagal menyimpan laporan terenkripsi ke $REPORT_FILENAME." >&2
        fi
    else
        echo "Error: Gagal mengenkripsi laporan." >&2
        fi

    echo "Tekan Enter untuk kembali ke menu utama..."
    read -r 
}
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
show_menu_decrypt(){
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
        return
    fi

    echo "Masukkan nama lengkap laporan yang ingin didekripsi (atau 'q' untuk keluar):"
    read -r pilihan

    if [[ "$pilihan" == "q" || "$pilihan" == "Q" ]]; then
        return
    fi

    if [[ "$pilihan" =~ ^[0-9]+$ ]]; then
        index=$((pilihan - 1))
        if [ "$index" -ge 0 ] && [ "$index" -lt "${#file_list[@]}" ]; then
            BERKAS_LAPORAN="${file_list[$index]}"
            dekripsi_laporan "$BERKAS_LAPORAN"
        else
            echo "Nomor tidak valid. Tekan Enter untuk melanjutkan..."
            read -r
            continue
        fi
    else
        echo "Input tidak valid. Masukkan nomor atau 'q' untuk keluar."
        read -r
    fi
done
}
while true; do
	show_menu
	read -r choice

	case "$choice" in
		1)
			submit_report
			;;
		2)
			show_menu_decrypt
			;;
		3)
			echo "Keluar dari HANTAM. Terima Kasih"
			exit 0
			;;
		
		*)
			echo "Invalid choice. Masukkan 1 atau 2!"
			echo "Tekan Enter untuk kembali..."
			read -r
			;;
	esac
done

