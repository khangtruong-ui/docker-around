#!/usr/bin/env bash
# ==============================================================================
# clean.sh - Clean LaTeX Auxiliary Build Files
# ==============================================================================
set -euo pipefail

TARGET="${1:-}"

if [[ -n "$TARGET" && -f "$TARGET" ]]; then
    echo "==> Cleaning auxiliary files for '$TARGET'..."
    latexmk -c "$TARGET" >/dev/null 2>&1 || true
else
    echo "==> Cleaning all LaTeX auxiliary files in current directory..."
    latexmk -c >/dev/null 2>&1 || true
    # Remove common auxiliary files not always tracked by latexmk
    rm -f *.aux *.bbl *.bcf *.blg *.dvi *.fdb_latexmk *.fls *.idx *.ilg *.ind \
          *.lof *.log *.lot *.nav *.out *.run.xml *.snm *.synctex.gz *.toc *.vrb \
          *.upa *.upb *-blx.bib 2>/dev/null || true
fi

echo "==> Clean complete."
