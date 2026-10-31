#!/usr/bin/env bash
# ==============================================================================
# compile.sh - Smart LaTeX Compiler for Antigravity & Developers
# ==============================================================================
set -euo pipefail

TARGET=""
ENGINE=""
CLEAN_AFTER=false
PVC_MODE=false
EXTRA_ARGS=()

show_help() {
    cat << EOF
Usage: $(basename "$0") [file.tex] [options]

Options:
  -e, --engine <engine>   Force engine: pdflatex (default), xelatex, or lualatex
  -c, --clean             Clean auxiliary files after successful build
  -w, --watch             Continuous compilation on file save (latexmk -pvc)
  -h, --help              Show this help message

If no target file is provided, compile.sh automatically searches for the main
LaTeX file (containing \\documentclass) in the current directory.
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_AFTER=true
            shift
            ;;
        -w|--watch)
            PVC_MODE=true
            shift
            ;;
        -*)
            EXTRA_ARGS+=("$1")
            shift
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# Auto-detect target file if not specified
if [[ -z "$TARGET" ]]; then
    if [[ -f "main.tex" ]]; then
        TARGET="main.tex"
    else
        # Find any .tex file containing \documentclass
        FOUND=$(grep -l -m 1 '^[^%]*\\documentclass' *.tex 2>/dev/null | head -n 1 || true)
        if [[ -n "$FOUND" ]]; then
            TARGET="$FOUND"
        else
            echo "Error: No target .tex file specified and no file with \\documentclass found in $(pwd)." >&2
            exit 1
        fi
    fi
fi

if [[ ! -f "$TARGET" ]]; then
    echo "Error: Target file '$TARGET' does not exist." >&2
    exit 1
fi

BASENAME="${TARGET%.tex}"

# Auto-detect engine if not manually set
if [[ -z "$ENGINE" ]]; then
    if grep -E -q '^[^%]*\\usepackage.*\{(fontspec|unicode-math|xeCJK)\}' "$TARGET" 2>/dev/null; then
        ENGINE="xelatex"
        echo "==> Auto-detected XeLaTeX dependency (fontspec/unicode-math)."
    elif grep -E -q '^[^%]*\\usepackage.*\{(luacode|luatex85)\}' "$TARGET" 2>/dev/null; then
        ENGINE="lualatex"
        echo "==> Auto-detected LuaLaTeX dependency."
    else
        ENGINE="pdflatex"
    fi
fi

# Build latexmk command
BUILD_FLAGS=("-synctex=1" "-interaction=nonstopmode" "-file-line-error")

case "$ENGINE" in
    xelatex)
        BUILD_FLAGS+=("-xelatex")
        ;;
    lualatex)
        BUILD_FLAGS+=("-lualatex")
        ;;
    pdflatex|*)
        BUILD_FLAGS+=("-pdf")
        ;;
esac

if [[ "$PVC_MODE" == true ]]; then
    BUILD_FLAGS+=("-pvc")
fi

echo "==> Compiling '$TARGET' using engine '$ENGINE' with latexmk..."
START_TIME=$(date +%s)

set +e
latexmk "${BUILD_FLAGS[@]}" "${EXTRA_ARGS[@]}" "$TARGET"
STATUS=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [[ $STATUS -eq 0 ]]; then
    PDF_FILE="${BASENAME}.pdf"
    if [[ -f "$PDF_FILE" ]]; then
        PDF_SIZE=$(du -h "$PDF_FILE" | cut -f1)
        echo "==> Compilation SUCCEEDED in ${DURATION}s!"
        echo "    Output: $PDF_FILE ($PDF_SIZE)"
    else
        echo "==> Compilation completed in ${DURATION}s."
    fi

    # Automatically generate / update arXiv-style HTML paper
    if command -v latex-to-html >/dev/null 2>&1; then
        latex-to-html "$TARGET" "${BASENAME}.html" >/dev/null 2>&1 || true
    fi

    if [[ "$CLEAN_AFTER" == true ]]; then
        echo "==> Cleaning auxiliary files..."
        latexmk -c "$TARGET" >/dev/null 2>&1 || true
    fi
    exit 0
else
    echo "==> Compilation FAILED with exit code $STATUS." >&2
    LOG_FILE="${BASENAME}.log"
    if [[ -f "$LOG_FILE" ]]; then
        echo "----------------- Error Summary from $LOG_FILE -----------------" >&2
        grep -n -C 2 -E '^! ' "$LOG_FILE" | head -n 30 >&2 || true
        echo "----------------------------------------------------------------" >&2
        echo "Tip: Run 'latex-clean' or inspect '$LOG_FILE' for complete details." >&2
    fi
    exit $STATUS
fi
