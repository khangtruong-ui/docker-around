#!/usr/bin/env bash
# ==============================================================================
# lint.sh - LaTeX Syntax & Style Linter using ChkTeX
# ==============================================================================
set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    if [[ -f "main.tex" ]]; then
        TARGET="main.tex"
    else
        TARGET=$(grep -l -m 1 '^[^%]*\\documentclass' *.tex 2>/dev/null | head -n 1 || true)
    fi
fi

if [[ -z "$TARGET" || ! -f "$TARGET" ]]; then
    echo "Usage: $(basename "$0") <document.tex>" >&2
    exit 1
fi

if ! command -v chktex >/dev/null 2>&1; then
    echo "Error: chktex is not installed." >&2
    exit 1
fi

echo "==> Running chktex lint on '$TARGET'..."
chktex -q -v2 "$TARGET" || true
echo "==> Lint complete."
