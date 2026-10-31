# LaTeX Best Practices Reference

## 1. Document Structure & Modularity

For medium-to-large projects, split chapters or sections into separate files using `\input{sections/sec1_intro}`:

```text
my-project/
├── main.tex
├── references.bib
├── sections/
│   ├── 01_introduction.tex
│   ├── 02_methodology.tex
│   └── 03_experiments.tex
└── figures/
    ├── architecture.pdf
    └── benchmark_chart.png
```

---

## 2. Professional Tables (`booktabs`)

**Never use vertical rules (`|`) in scientific papers.**
Use horizontal separators from the `booktabs` package:

```latex
\usepackage{booktabs}

\begin{table}[htbp]
\centering
\caption{Model Performance Comparison}
\label{tab:performance}
\begin{tabular}{@{}llcc@{}}
\toprule
\textbf{Architecture} & \textbf{Dataset} & \textbf{Accuracy (\%)} & \textbf{Latency (ms)} \\
\midrule
ResNet-50             & ImageNet         & 76.1                   & 12.4                  \\
Vision Transformer    & ImageNet         & 81.2                   & 24.1                  \\
Ours (Hybrid)         & ImageNet         & \textbf{83.5}          & \textbf{14.8}         \\
\bottomrule
\end{tabular}
\end{table}
```

---

## 3. Clear Mathematics (`amsmath`)

- Multi-line aligned equations:
```latex
\begin{align}
  y &= W x + b \label{eq:linear} \\
  \hat{y} &= \sigma(y) \label{eq:sigmoid}
\end{align}
```
- Reference equations using `\eqref{eq:linear}` (automatically produces `(1)` with parentheses).
- Use `\mathbb{R}` for real numbers, `\mathcal{L}` for loss functions, `\mathbf{x}` for vectors.

---

## 4. Source Code Listings (`listings` or `minted`)

For clean syntax-highlighted code:
```latex
\usepackage{listings}
\usepackage{xcolor}

\lstset{
    basicstyle=\ttfamily\small,
    keywordstyle=\color{blue}\bfseries,
    commentstyle=\color{gray}\itshape,
    stringstyle=\color{teal},
    frame=single,
    breaklines=true
}
```
If using `minted` (which relies on Python `pygments`), pass `-shell-escape` to `latexmk`:
```bash
latexmk -pdf -shell-escape main.tex
```
