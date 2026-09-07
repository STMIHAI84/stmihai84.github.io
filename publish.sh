#!/usr/bin/env bash
# Reface pagina si PDF-urile din ~/Documente/CV, apoi publica pe GitHub Pages.
set -e
cd ~/Documente/CV
for L in "" _RO _RU; do
  google-chrome --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$HOME/Documente/CV/Mihail_Stingaci_CV_2026${L}.pdf" \
    "file://$HOME/Documente/CV/Mihail_Stingaci_CV_2026${L}.html" >/dev/null 2>&1
done
cd ~/cv-site
cp ~/Documente/CV/cv-web.html index.html
cp ~/Documente/CV/Mihail_Stingaci_CV_2026.pdf    cv-en.pdf
cp ~/Documente/CV/Mihail_Stingaci_CV_2026_RO.pdf cv-ro.pdf
cp ~/Documente/CV/Mihail_Stingaci_CV_2026_RU.pdf cv-ru.pdf
git add -A
git commit -m "Actualizare CV $(date +%F)" || { echo "Nimic de publicat."; exit 0; }
git push
echo "Gata: https://stmihai84.github.io"
