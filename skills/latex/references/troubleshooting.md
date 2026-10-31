# LaTeX Troubleshooting & Error Diagnostics

When compiling LaTeX, errors are written to `<filename>.log`. Here are the most common errors and how to fix them:

---

### 1. `! Undefined control sequence`
- **Cause**: A macro/command is misspelled or its required package has not been imported.
- **Example**: `\toprule` without `\usepackage{booktabs}` or `\eqref` without `\usepackage{amsmath}`.
- **Fix**: Check spelling of the command or add the missing `\usepackage{...}` in the preamble.

---

### 2. `! LaTeX Error: File 'xxx.sty' not found`
- **Cause**: A package is missing from the TeX Live distribution.
- **Fix**: Find which Ubuntu package provides the file via `apt-file search xxx.sty` or check if it is part of `texlive-science` or `texlive-latex-extra`. If it is a local custom style, ensure `xxx.sty` is in the same directory as `main.tex`.

---

### 3. `! Missing $ inserted` or `! Display math should end with $$`
- **Cause**: A math-mode symbol (such as `_`, `^`, `\alpha`, `\sum`) is used in plain text outside of `$...$` or `\[...\]`.
- **Fix**: If an underscore is intended as literal text (e.g. `my_variable`), escape it as `my\_variable` or wrap in `\texttt{my\_variable}`. If math, enclose in `$ ... $`.

---

### 4. `! Emergency stop`
- **Cause**: LaTeX encountered a fatal error and exited immediately (often caused by an unclosed group or missing file).
- **Fix**: Look immediately above `! Emergency stop` in the `.log` file for the primary error.

---

### 5. `! Paragraph ended before \xxx was complete`
- **Cause**: An opening bracket `{` was left unclosed before an empty line / paragraph break.
- **Fix**: Find the line referenced and inspect the balancing of curly braces `{}` or arguments to `\textbf{}`, `\section{}`, or math macros.

---

### 6. Citation `[?]` or `Warning: Citation 'xxx' on page X undefined`
- **Cause**: The citation key does not match `references.bib`, or BibTeX / Biber has not been executed yet.
- **Fix**: Run `latexmk -pdf` (or `latex-compile`) which runs `bibtex`/`biber` and reruns `pdflatex` until references resolve. If using standard bibtex, check that `\bibliographystyle` and `\bibliography` are declared.

---

### 7. Overfull `\hbox` (too wide by Xpt)
- **Cause**: A line of text, URL, code snippet, or equation exceeds the margins of the column.
- **Fix**:
  - For URLs: use `\usepackage{xurl}` or `\url{}` to allow breaking anywhere.
  - For equations: split across lines using `amsmath`'s `\begin{split}` or `\begin{align}`.
  - For tables: use `\resizebox{\columnwidth}{!}{...}` or `p{width}` column specifiers.
