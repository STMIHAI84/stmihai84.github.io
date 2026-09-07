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

# index.html = document complet (head cu Open Graph) + continutul paginii
TITLE="Mihail Stîngaci — Backend / Full-Stack Developer"
DESC="Symfony, Node.js si microservicii event-driven pentru platforme de comunicare in timp real. CV in romana, rusa, engleza si franceza."
{
  cat <<HEAD
<!doctype html>
<html lang="ro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$TITLE</title>
<meta name="description" content="$DESC">
<meta name="author" content="Mihail Stîngaci">
<link rel="canonical" href="https://stmihai84.github.io/">
<meta property="og:type" content="profile">
<meta property="og:site_name" content="Mihail Stîngaci">
<meta property="og:title" content="$TITLE">
<meta property="og:description" content="$DESC">
<meta property="og:url" content="https://stmihai84.github.io/">
<meta property="og:image" content="https://stmihai84.github.io/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="$TITLE">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$TITLE">
<meta name="twitter:description" content="$DESC">
<meta name="twitter:image" content="https://stmihai84.github.io/og.png">
</head>
<body>
HEAD
  grep -vE '^<title>|^<meta charset' "$SRC/cv-web.html"
  printf '</body>\n</html>\n'
} > "$SITE/index.html"

cd "$SITE"
git add -A
if git diff --cached --quiet; then
  echo "Nimic de publicat."
  exit 0
fi
git commit -q -m "Actualizare CV $(date +%F)"
git pull --rebase --quiet || true   # ia ce a scris GitHub (ex. fisierul CNAME)
git push -q
echo "Publicat: https://stmihai84.github.io"
