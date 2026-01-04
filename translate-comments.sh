#!/bin/bash

# ============================================
# BATCH TRANSLATE ALL .RSC COMMENTS TO INDONESIAN
# ============================================

echo "🇮🇩 Starting batch translation of all .rsc files..."
echo ""

# Make a backup branch just in case
git checkout -b translation-backup

cd ~/routeros-sc

# Counter untuk tracking
COUNTER=0

# === COMMON TRANSLATIONS ===

echo "1. Translating 'RouterOS script:'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# RouterOS script:/# Skrip RouterOS:/g' {} +
((COUNTER++))

echo "2. Translating 'global configuration'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# global configuration/# konfigurasi global/g' {} +
((COUNTER++))

echo "3. Translating 'Warning:'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Warning:/# Peringatan:/g' {} +
((COUNTER++))

echo "4. Translating 'Do \*NOT\* copy'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Do \*NOT\* copy/# JANGAN copy/g' {} +
((COUNTER++))

echo "5. Translating 'Set this to'..."
find . -name "*.rsc" -type f -exec sed -i '' "s/# Set this to/# Atur ke/g" {} +
((COUNTER++))

echo "6. Translating 'Add extra'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Add extra/# Tambah ekstra/g' {} +
((COUNTER++))

echo "7. Translating 'You can send'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# You can send/# Anda dapat mengirim/g' {} +
((COUNTER++))

echo "8. Translating 'Configure'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Configure/# Konfigurasi/g' {} +
((COUNTER++))

echo "9. Translating 'Install'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Install/# Instal/g' {} +
((COUNTER++))

echo "10. Translating 'Enable'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Enable/# Aktifkan/g' {} +
((COUNTER++))

echo "11. Translating 'Disable'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Disable/# Nonaktifkan/g' {} +
((COUNTER++))

echo "12. Translating 'Note:'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Note:/# Catatan:/g' {} +
((COUNTER++))

echo "13. Translating 'This is used'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# This is used/# Ini digunakan/g' {} +
((COUNTER++))

echo "14. Translating 'Use this'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Use this/# Gunakan ini/g' {} +
((COUNTER++))

echo "15. Translating 'Run'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Run/# Jalankan/g' {} +
((COUNTER++))

echo "16. Translating 'Check'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Check/# Periksa/g' {} +
((COUNTER++))

echo "17. Translating 'Load'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Load/# Muat/g' {} +
((COUNTER++))

echo "18. Translating 'Download'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Download/# Unduh/g' {} +
((COUNTER++))

echo "19. Translating 'Update'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Update/# Perbarui/g' {} +
((COUNTER++))

echo "20. Translating 'Send'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Send/# Kirim/g' {} +
((COUNTER++))

echo "21. Translating 'Info:'..."
find . -name "*.rsc" -type f -exec sed -i '' 's/# Info:/# Info:/g' {} +
((COUNTER++))

echo ""
echo "✅ Translasi selesai! ($COUNTER translations applied)"
echo ""
echo "=== SUMMARY ==="
echo "Total .rsc files:"
find . -name "*.rsc" -type f | wc -l
echo ""
echo "Changed files:"
git diff --name-only | grep ".rsc" | wc -l
echo ""
echo "=== NEXT STEPS ==="
echo "1. Review changes: git diff | head -200"
echo "2. Commit: git add *.rsc && git commit -m 'Translate all .rsc comments to Indonesian'"
echo "3. Push: git push origin main"
echo ""
echo "✨ Done! Press Enter to continue..."
read
