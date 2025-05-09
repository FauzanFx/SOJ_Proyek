#!/bin/bash

#Mendefinisikan Direktori dan Subdirektori

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"
GPG_RECIPIENT_KEY="0624CF4C2CE76D2DBB419074B001B6FC013FB655"

#Fungsi-fungsi
show_menu(){
	clear
	echo "===================================="
	echo "Hantam: Sistem Laporan Anonimus	"
	echo "===================================="
	echo "1. Submit Laporan"
	echo "2. Exit"
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

    # Gunakan echo -e untuk memasukkan string formatted_report dengan karakter newline yang diinterpretasikan
    # Pipe ke gpg untuk enkripsi
    # --encrypt: lakukan enkripsi
    # --recipient <key_id>: tentukan kunci penerima
    # --armor: keluarkan dalam format ASCII armored (berbasis teks)
    # --output -: kirim output ke standard output (yang kita tangkap)
    encrypted_report=$(echo -e "$formatted_report" | gpg --encrypt --recipient "$GPG_RECIPIENT_KEY" --armor --output -)

    # Periksa status keluar dari perintah gpg
    if [ $? -eq 0 ]; then
        echo "Laporan berhasil dienkripsi."
        # Variabel 'encrypted_report' sekarang menyimpan data terenkripsi.

        # --- Langkah 6: Simpan Laporan Terenkripsi ke Direktori Aman ---

        # Tentukan nama file menggunakan ID Laporan yang unik
        REPORT_FILENAME="$REPORTS_DIR/${REPORT_ID}.asc" # Menggunakan ekstensi .asc untuk file GPG ASCII armored

        echo "Menyimpan laporan terenkripsi ke $REPORT_FILENAME ..."

        # Simpan konten terenkripsi ke dalam file
        echo "$encrypted_report" > "$REPORT_FILENAME"

        # Periksa apakah penyimpanan berhasil
        if [ $? -eq 0 ]; then
            echo "Laporan berhasil disimpan."

            # --- Atur Izin untuk Keamanan ---
            # Restrict access to the reports directory itself (optional here, better in setup)
            # chmod 700 "$REPORTS_DIR"

            chmod 600 "$REPORT_FILENAME" # Pemilik dapat membaca/menulis, pengguna lain tidak memiliki izin

            echo "Izin diatur untuk $REPORT_FILENAME."

            # --- Pesan Sukses Akhir ---
            echo "-----------------------------------------------"
            echo "Laporan berhasil dikirim dan disimpan dengan aman."
            echo "Terima kasih atas keberanian Anda."
            echo "-----------------------------------------------"
	else
            # Tangani kegagalan penyimpanan
            echo "Error: Gagal menyimpan laporan terenkripsi ke $REPORT_FILENAME." >&2
        fi
    else
        echo "Error: Gagal mengenkripsi laporan." >&2
        fi

    echo "Tekan Enter untuk kembali ke menu utama..."
    read -r # Tunggu pengguna menekan Enter
}


#Main Program

while true; do
	show_menu
	read -r choice

	case "$choice" in
		1)
			submit_report
			;;
		2)
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

