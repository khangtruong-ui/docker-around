#!/usr/bin/env bash
# ==============================================================================
# latex-to-html.sh - Converts LaTeX documents to responsive arXiv-style HTML5
# ==============================================================================
set -euo pipefail

SRC="${1:-}"
OUT="${2:-}"

if [[ -z "$SRC" ]]; then
    if [[ -f "main.tex" ]]; then
        SRC="main.tex"
    else
        SRC=$(grep -l -m 1 '^[^%]*\\documentclass' *.tex 2>/dev/null | head -n 1 || true)
        if [[ -z "$SRC" ]]; then
            echo "Error: No target LaTeX file found." >&2
            exit 1
        fi
    fi
fi

if [[ ! -f "$SRC" ]]; then
    echo "Error: Source file '$SRC' does not exist." >&2
    exit 1
fi

BASENAME="${SRC%.tex}"
if [[ -z "$OUT" ]]; then
    OUT="${BASENAME}.html"
fi

THEME_CSS="/usr/local/share/latex-html/arxiv-theme.css"
HEADER_OPT=()
if [[ -f "$THEME_CSS" ]]; then
    HEADER_OPT=("--include-in-header=$THEME_CSS")
fi

echo "==> Converting '$SRC' to arXiv-style HTML paper..."
START_TIME=$(date +%s)

if command -v pandoc >/dev/null 2>&1; then
    pandoc -s "$SRC" \
        --mathjax \
        "${HEADER_OPT[@]}" \
        -o "$OUT" 2>/dev/null || {
            echo "==> Pandoc had a minor warning/error, attempting pdftohtml fallback..."
            PDF_SRC="${BASENAME}.pdf"
            if [[ -f "$PDF_SRC" ]] && command -v pdftohtml >/dev/null 2>&1; then
                pdftohtml -c -s -noframes "$PDF_SRC" "$OUT" >/dev/null 2>&1 || true
            fi
        }
elif command -v pdftohtml >/dev/null 2>&1; then
    PDF_SRC="${BASENAME}.pdf"
    if [[ -f "$PDF_SRC" ]]; then
        pdftohtml -c -s -noframes "$PDF_SRC" "$OUT" >/dev/null 2>&1 || true
    fi
else
    echo "Warning: Neither pandoc nor pdftohtml available for HTML conversion." >&2
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [[ -f "$OUT" ]]; then
    SIZE=$(du -h "$OUT" | cut -f1)
    echo "==> arXiv-style HTML generation SUCCEEDED in ${DURATION}s!"
    echo "    Output: $OUT ($SIZE)"
else
    echo "==> Warning: Failed to generate $OUT" >&2
fi
