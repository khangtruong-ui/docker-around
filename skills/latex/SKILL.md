---
name: latex
description: >-
  Provides end-to-end guidance, automated procedures, and diagnostic workflows for writing,
  compiling, formatting, linting, and troubleshooting LaTeX documents, academic papers, reports,
  and Beamer presentations. Activate whenever the user asks to create, edit, compile, clean,
  debug LaTeX (.tex) files, configure bibliographies (BibTeX/Biber), or fix LaTeX build errors.
---

# LaTeX Skill for Antigravity (`agy`)

This skill equips the Antigravity agent with a comprehensive runbook and helper tools
for professional LaTeX authoring, automated compilation, error diagnostics, and quality checks.

---

## 1. Quick Helper Scripts

Helper scripts are installed alongside this skill in `scripts/`:

| Helper Script | Purpose | Example Usage |
| :--- | :--- | :--- |
| **`compile.sh`** | Smart compilation with engine auto-detection & clean error extraction | `./scripts/compile.sh document.tex` |
| **`clean.sh`** | Safely clean auxiliary build artifacts (`.aux`, `.bbl`, `.log`, etc.) | `./scripts/clean.sh` |
| **`lint.sh`** | Run `chktex` linting and report formatting/syntax suggestions | `./scripts/lint.sh document.tex` |
| **`template.sh`** | Scaffold new LaTeX projects (`article`, `paper`, `beamer`, `report`) | `./scripts/template.sh paper` |

All scripts can also be invoked system-wide via:
- `latex-compile [file.tex]`
- `latex-clean`
- `latex-lint [file.tex]`
- `latex-template [type]`

---

## 2. Compilation Strategy & Rules

1. **Always use `latexmk` by default**:
   `latexmk` automatically manages multi-pass compilation (resolving citations, labels, tables of contents, and cross-references) and detects when BibTeX / Biber reruns are necessary.
   - For standard documents:
     ```bash
     latexmk -pdf -synctex=1 -interaction=nonstopmode -file-line-error main.tex
     ```
   - For documents requiring modern fonts (`fontspec`), Unicode, or OpenType:
     ```bash
     latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error main.tex
     ```
   - For documents using LuaTeX:
     ```bash
     latexmk -lualatex -synctex=1 -interaction=nonstopmode -file-line-error main.tex
     ```

2. **Continuous preview mode (`-pvc`)**:
   When pairing or live-editing, `latexmk -pvc -pdf main.tex` watches the source files and recompiles automatically whenever changes are saved.

3. **Log & Error Analysis**:
   When compilation fails:
   - Check the exit code and `.log` file (`main.log`).
   - Search for lines starting with `!` or `error:` to pinpoint the exact line number.
   - Consult [references/troubleshooting.md](./references/troubleshooting.md) for root-cause diagnosis.

---

## 3. Reference Documentation (Progressive Disclosure)

When in-depth details are required, consult the subdocuments in `references/`:
- **Compilation Engine Guide**: [references/compilation.md](./references/compilation.md)
- **Troubleshooting & Error Catalog**: [references/troubleshooting.md](./references/troubleshooting.md)
- **Best Practices & Math/Table Guidelines**: [references/best_practices.md](./references/best_practices.md)
