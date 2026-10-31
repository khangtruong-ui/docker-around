# LaTeX Compilation Reference

## 1. Engine Selection

| Engine | Best For | Characteristics | Key Packages |
| :--- | :--- | :--- | :--- |
| **`pdflatex`** | Standard papers, journals (IEEE, ACM, Springer, arXiv) | Fastest compile times, microtype support, standard 8-bit fonts | `inputenc`, `fontenc`, `amsmath`, `graphicx` |
| **`xelatex`** | Multilingual, system TrueType/OpenType fonts, CJK | Native Unicode support, custom OS fonts via `fontspec` | `fontspec`, `unicode-math`, `xeCJK` |
| **`lualatex`** | Complex dynamic scripting, modern OpenType math | Embedded Lua scripting engine, large memory limits | `luacode`, `fontspec`, `unicode-math` |

---

## 2. Recommended `latexmk` Flags

- `-pdf`: Generate PDF output using `pdflatex`.
- `-xelatex`: Generate PDF output using `xelatex`.
- `-lualatex`: Generate PDF output using `lualatex`.
- `-synctex=1`: Embed SyncTeX forward/inverse search coordinates (enables clicking from PDF to source and source to PDF).
- `-interaction=nonstopmode`: Compile without pausing for interactive prompts on errors.
- `-file-line-error`: Output errors in standard `file:line:error` format for IDE parsers.
- `-pvc`: Preview Continuous - automatically recompile when source files change.
- `-c`: Remove auxiliary build files (`.aux`, `.bbl`, `.log`, etc.) while keeping the final PDF.
- `-C`: Full clean, removes all generated files including the final PDF.

---

## 3. Global `.latexmkrc` Configuration

Placing a `.latexmkrc` file in `~/.latexmkrc` or in your project root sets sane defaults:

```perl
# ~/.latexmkrc
$pdf_mode = 1;
$postscript_mode = $dvi_mode = 0;
$bibtex_use = 2;
set_tex_cmds('-synctex=1 -interaction=nonstopmode -file-line-error %O %S');
```
