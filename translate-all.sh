#!/bin/bash
find . -name "*.rsc" -type f -exec sed -i '' 's/# RouterOS script:/# Skrip RouterOS:/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# global configuration/# konfigurasi global/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Warning:/# Peringatan:/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Do \*NOT\* copy/# JANGAN copy/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Set this to/# Atur ke/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Add extra/# Tambah ekstra/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# You can send/# Anda dapat mengirim/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Configure/# Konfigurasi/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Install/# Instal/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Enable/# Aktifkan/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Disable/# Nonaktifkan/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Note:/# Catatan:/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# This is used/# Ini digunakan/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Use this/# Gunakan ini/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Run/# Jalankan/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Check/# Periksa/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Load/# Muat/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Download/# Unduh/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Update/# Perbarui/g' {} +
find . -name "*.rsc" -type f -exec sed -i '' 's/# Send/# Kirim/g' {} +
echo "✅ Done!"
git add *.rsc
git commit -m "Translate ALL .rsc comments to Indonesian"
git push origin main
