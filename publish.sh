#!/usr/bin/env bash
# Regenereaza PDF-urile si publica pagina pe https://stmihai84.github.io
#
#   ~/Documente/CV/   -> PDF-uri COMPLETE (cu telefon), pentru trimis pe email
#   ~/cv-site/        -> PDF-uri PUBLICE  (fara telefon), pentru site
set -euo pipefail

SRC="$HOME/Documente/CV"
SITE="$HOME/cv-site"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$SRC" && python3 translate_cv.py >/dev/null && python3 translate_cv_fr.py >/dev/null

pdf () {  # pdf <fisier.html> <iesire.pdf>
  google-chrome --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$2" "file://$1" >/dev/null 2>&1
}

for pair in ":en" "_RO:ro" "_RU:ru" "_FR:fr"; do
  suf="${pair%%:*}"; lang="${pair##*:}"
  html="$SRC/Mihail_Stingaci_CV_2026${suf}.html"

  # 1. varianta completa, cu telefon
  pdf "$html" "$SRC/Mihail_Stingaci_CV_2026${suf}.pdf"

  # 2. varianta publica: scoate randul cu numarul de telefon
  perl -0pe 's{<span><b>[^<]*</b>\s*&nbsp;\+373[^<]*</span>\s*}{}g' "$html" > "$TMP/$lang.html"
  if grep -q '+373' "$TMP/$lang.html"; then
    echo "EROARE: numarul de telefon a ramas in varianta publica ($lang). Opresc." >&2
    exit 1
  fi
  pdf "$TMP/$lang.html" "$SITE/cv-$lang.pdf"
done

cp "$SRC/cv-web.html" "$SITE/index.html"

cd "$SITE"
git add -A
if git diff --cached --quiet; then
  echo "Nimic de publicat."
  exit 0
fi
git commit -q -m "Actualizare CV $(date +%F)"
git push -q
echo "Publicat: https://stmihai84.github.io"
