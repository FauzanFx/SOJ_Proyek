#!/bin/bash

#Mendefinisikan Direktori dan Subdirektori

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$BASE_DIR/report"

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

	echo "-----------------------------------------------"
    	echo "Report received (will be processed securely)."
	echo "Tekan Enter untuk kembali ke menu utama..."
	read -r
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

