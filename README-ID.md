# Skrip RouterOS - Panduan Bahasa Indonesia

🇮🇩 **Distribusi Pribadi untuk Penggunaan Lokal**

**PERHATIAN**: Repository ini adalah distribusi pribadi untuk kebutuhan internal Dumai, Riau. Tidak ada garansi resmi atau dukungan. Gunakan dengan risiko Anda sendiri.

## Daftar Isi

- [Tentang](#tentang)
- [Syarat & Ketentuan](#syarat--ketentuan)
- [Instalasi Cepat](#instalasi-cepat)
- [Instalasi Lengkap](#instalasi-lengkap)
- [Konfigurasi](#konfigurasi)
- [Update Script](#update-script)
- [List Script Tersedia](#list-script-tersedia)
- [FAQ](#faq)

## Tentang

Ini adalah kumpulan script untuk mengotomasi dan memperluas fitur **MikroTik RouterOS**. Script ini terinspirasi dari [eworm-de/routeros-scripts](https://github.com/eworm-de/routeros-scripts) tetapi dikustomisasi untuk kebutuhan lokal.

### Fitur Utama

- ✅ Backup otomatis (cloud, email, upload server)
- ✅ Monitor kesehatan router (CPU, RAM, temperature)
- ✅ Notifikasi via Telegram, Email, Ntfy
- ✅ Update sertifikat otomatis
- ✅ DHCP ke DNS integration
- ✅ Firewall address-list update otomatis
- ✅ Dan banyak lagi...

## Syarat & Ketentuan

### Kebutuhan RouterOS

- **RouterOS v7.x** (minimal)
- Untuk RouterOS v6, gunakan branch `routeros-v6`
- Storage minimal: 100MB kosong (untuk script + backup)
- RAM minimal: 128MB (untuk eksekusi script)

### Fitur yang Harus Enable (RouterOS 7.17+)

Ada beberapa router modern yang menggunakan "Device Mode" dengan fitur terbatas. Pastikan enable:

```
scheduler - untuk auto-run script
fetch - untuk download script dari GitHub
```

## Instalasi Cepat

**Untuk pengguna yang sudah tahu RouterOS**, copy-paste command ini di Terminal:

```routeros
{ :local BaseUrl "https://raw.githubusercontent.com/dumkot/routeros-sc/main/"; :local CertCommonName "ISRG Root X2"; :local CertFileName "ISRG-Root-X2.pem"; :local CertFingerprint "69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470"; :local CertSettings [ /certificate/settings/get ]; :if (!((($CertSettings->"builtin-trust-anchors") = "trusted" || \ ($CertSettings->"builtin-trust-store") ~ "fetch" || \ ($CertSettings->"builtin-trust-store") = "all") && \ [[ :parse (":return [ :len [ /certificate/builtin/find where common-name=\"" . $CertCommonName . "\" ] ]") ]] > 0)) do={ :put "Importing certificate..."; /tool/fetch ($BaseUrl . "certs/" . $CertFileName) dst-path=$CertFileName as-value; :delay 1s; /certificate/import file-name=$CertFileName passphrase=""; :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] != 1) do={ :error "Something is wrong with your certificates!"; }; :delay 1s; }; :put "Renaming global-config-overlay, if exists..."; /system/script/set name=("global-config-overlay-" . [ /system/clock/get date ] . "-" . [ /system/clock/get time ]) [ find where name="global-config-overlay" ]; :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={ :put "Installing $Script..."; /system/script/remove [ find where name=$Script ]; /system/script/add name=$Script owner=$Script source=([ /tool/fetch check-certificate=yes-without-crl ($BaseUrl . $Script . ".rsc") output=user as-value ]->"data"); }; :put "Loading configuration and functions..."; /system/script { run global-config; run global-functions; }; :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] > 0) do={ :put "Renaming certificate by its common-name..."; :global CertificateNameByCN; $CertificateNameByCN $CertFingerprint; }; };
```

Lalu lanjutkan ke **[Konfigurasi](#konfigurasi)**.

## Instalasi Lengkap

### 1. Download Sertifikat (Pilih 1)

**Opsi A: RouterOS 7.19+ (ada built-in certificate store)**

Jika RouterOS Anda sudah v7.19+, jalankan ini untuk enable built-in trust:

```routeros
/certificate/settings/set builtin-trust-store=fetch;
```

**Opsi B: Manual download (untuk RouterOS lama)**

Download sertifikat ISRG Root X2 dari browser Anda, lalu import di RouterOS:

```routeros
/tool/fetch "https://raw.githubusercontent.com/dumkot/routeros-sc/main/certs/ISRG-Root-X2.pem" dst-path="isrg-root-x2.pem";
/certificate/import file-name="isrg-root-x2.pem" passphrase="";
```

Verifikasi:

```routeros
/certificate/print where fingerprint="69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470";
```

### 2. Download Script Inti

```routeros
:foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={ /system/script/add name=$Script owner=$Script source=([ /tool/fetch check-certificate=yes-without-crl ("https://raw.githubusercontent.com/dumkot/routeros-sc/main/" . $Script . ".rsc") output=user as-value ]->"data"); };
```

### 3. Jalankan Script

```routeros
/system/script { run global-config; run global-functions; };
```

Lihat di terminal apakah ada error. Jika ada, itu biasanya berarti RouterOS perlu update.

### 4. Konfigurasi

Edit file `global-config-overlay` sesuai kebutuhan Anda:

```routeros
/system/script/edit global-config-overlay source;
```

Kemudian jalankan ulang:

```routeros
/system/script/run global-config;
```

### 5. Auto-Update (Opsional)

Jika ingin script auto-update setiap hari:

```routeros
/system/scheduler/add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;";
```

## Konfigurasi

File `global-config-overlay` berisi pengaturan yang Anda butuhkan. Copy bagian yang Anda inginkan dari `global-config` (tanpa -overlay) ke `global-config-overlay`.

### Contoh Konfigurasi

**Backup Email**

```routeros
:global BackupPassword "sangat-rahasia";
:global BackupSendEmail 1;
:global SendNotification 1;
:global NotificationEmail "admin@dumai.go.id";
:global MailServer "mail.dumai.go.id";
:global MailFrom "router@dumai.go.id";
```

**Telegram Notification**

```routeros
:global NotificationTelegram 1;
:global TelegramBotToken "123456:ABCdefg...";
:global TelegramChatID "123456789";
```

**Monitor Kesehatan**

```routeros
:global HealthNotification 1;
:global HealthTempWarn 60;
:global HealthTempCrit 80;
```

Setelah ubah, jalankan:

```routeros
/system/script/run global-config;
```

## Update Script

Jika sudah terpasang, untuk update semua script ke versi terbaru:

```routeros
$ScriptInstallUpdate;
```

Jika ada update script baru atau changelog, Anda akan dapat notifikasi otomatis.

## Menambah Script Baru

Misalnya ingin tambah `check-routeros-update`:

```routeros
$ScriptInstallUpdate check-routeros-update;
```

Lalu biasanya perlu tambah scheduler:

```routeros
/system/scheduler/add name="check-routeros-update" interval=1d start-time=startup on-event="/system/script/run check-routeros-update;";
```

## List Script Tersedia

| Script | Fungsi |
|--------|--------|
| `backup-cloud` | Upload backup ke Mikrotik cloud |
| `backup-email` | Kirim backup via email |
| `backup-partition` | Simpan config ke partition fallback |
| `backup-upload` | Upload backup ke server FTP/HTTP |
| `check-certificates` | Monitor & renew sertifikat |
| `check-health` | Monitor CPU, RAM, suhu |
| `check-routeros-update` | Cek update RouterOS |
| `dhcp-to-dns` | Sync DHCP lease ke DNS |
| `fw-addr-lists` | Update firewall address-list otomatis |
| `netwatch-notify` | Notifikasi host up/down |
| `telegram-chat` | Bot Telegram untuk kontrol router |
| `update-gre-address` | Update GRE config dengan IP dinamis |
| [Lihat semua...](./README.md#available-scripts) | |

## Troubleshooting

### Masalah: Script tidak bisa download

**Error**: `failure: certificate not found`

**Solusi**: Pastikan sertifikat sudah import dan trusted. Lihat bagian "Download Sertifikat".

### Masalah: Notifikasi tidak jalan

**Cek**:
- Email: Setting `MailServer`, `MailFrom` sudah benar?
- Telegram: Bot token dan Chat ID valid?
- Ntfy.sh: Token valid dan endpoint terbuka?

Jalankan test:

```routeros
:global SendNotification 1;
/system/script/run send-notification;
```

### Masalah: Script jalankan error

Lihat log:

```routeros
/log print where topics~"script";
```

Biasanya error adalah karena RouterOS terlalu lama (perlu update). Update dulu, lalu coba ulang.

## FAQ

**Q: Apakah ini resmi dari Mikrotik?**

A: Tidak. Ini adalah distribusi pribadi yang terinspirasi dari eworm-de/routeros-scripts.

**Q: Apakah aman dipakai di production?**

A: Tergantung. Sudah dicoba di lingkungan lokal, tapi tidak ada garansi. Test di router non-critical dulu.

**Q: Bagaimana jika ada bug?**

A: Issues/reports bisa ke repository ini, tapi tidak ada SLA. Untuk support profesional, hubungi eworm-de upstream atau profesional lokal.

**Q: Bisa pake di RouterOS v6?**

A: Ada branch terpisah `routeros-v6`. Tapi maintenance sudah minimalis.

**Q: Bisa contribute / fork?**

A: Ya, silakan fork dan adjust sesuai kebutuhan. Jangan lupa credit upstream eworm-de jika buat public fork.

## Upstream & Kredit

- **Upstream utama**: [eworm-de/routeros-scripts](https://github.com/eworm-de/routeros-scripts) - Christian Hesse
- **Repository ini**: Kustomisasi lokal oleh [dumkot](https://github.com/dumkot) untuk Dumai, Riau

## Lisensi

GNU General Public License v3 (GPLv3) - Lihat [LICENSE](./COPYING.md)

---

**Catatan**: Versi Inggris lengkap ada di [README.md](./README.md)
