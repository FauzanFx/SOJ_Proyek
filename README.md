#HANTAM - Harapan AmaN untuk TindAk Melawan kekerasan Seksual
============================================================

Deskripsi:
----------
HANTAM adalah sistem pelaporan kekerasan seksual berbasis Bash Script yang bersifat anonim. Laporan yang dikirim akan dienkripsi dengan GPG untuk menjamin kerahasiaan. Sistem ini memiliki antarmuka berbasis terminal dengan pilihan menu interaktif.

Fitur:
------
- Validasi tanggal dan lokasi kejadian.
- Pilihan jenis kekerasan secara multi-select (fisik, verbal, dll).
- Input deskripsi kejadian (opsional).
- Enkripsi laporan menggunakan GPG.
- Sistem status laporan: belum dibuka (undecrypted) & sudah dibuka (decrypted).
- Alat dekripsi laporan bagi pemilik kunci GPG.

Struktur File:
--------------
hantam/
├── hantam.sh         --> Skrip utama
├── config.sh         --> Konfigurasi GPG & direktori
└── reports/          --> Folder laporan terenkripsi

Konfigurasi:
------------
1. Melakukan setup terlebih dahulu menggunakan setup.sh
2. Mengecek config.sh terlebih dahulu

Menjalankan:
------------
1. Ubah izin file agar dapat dieksekusi:
   chmod +x hantam.sh

2. Jalankan skrip:
   ./hantam.sh

Alur Penggunaan:
----------------
- Submit Laporan:
  > Masukkan tanggal, lokasi, jenis kekerasan, dan deskripsi (opsional).
  > Laporan akan dienkripsi dan disimpan otomatis.

- Decrypt Tool:
  > Tampilkan daftar laporan.
  > Pilih laporan berdasarkan nomor.
  > Laporan akan didekripsi jika kunci privat cocok.

Keamanan:
---------
- Laporan dienkripsi menggunakan GPG (asymmetric encryption).
- Tidak menyimpan data identitas pribadi.
- ID laporan dibuat otomatis menggunakan UUID.
- Status laporan disimpan dalam file `.status.undecrypted` dan `.status.decrypted`.

Dependensi:
-----------
- bash
- gpg
- uuidgen (opsional, fallback ke /dev/urandom)
- coreutils (untuk perintah `stat`, `date`, dll)
