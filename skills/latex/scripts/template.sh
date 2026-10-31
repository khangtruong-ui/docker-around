#!/usr/bin/env bash
# ==============================================================================
# template.sh - Scaffold Starter Templates for LaTeX Projects
# ==============================================================================
set -euo pipefail

TYPE="${1:-article}"
DEST_DIR="${2:-.}"

mkdir -p "$DEST_DIR"

case "$TYPE" in
    paper|ieee|acm)
        cat << 'EOF' > "$DEST_DIR/main.tex"
\documentclass[conference,10pt]{IEEEtran}
\IEEEoverridecommandlockouts

\usepackage{cite}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{algorithmic}
\usepackage{graphicx}
\usepackage{textcomp}
\usepackage{xcolor}
\usepackage{booktabs}
\usepackage{hyperref}

\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    citecolor=blue,
    urlcolor=blue
}

\begin{document}

\title{Paper Title: An Autonomous LaTeX \& AI Workflow}

\author{\IEEEauthorblockN{Author Name}
\IEEEauthorblockA{\textit{Department of Computer Science} \\
\textit{University / Institution}\\
City, Country \\
email@example.com}
}

\maketitle

\begin{abstract}
This is the abstract summarizing the contributions, methodology, and key experimental findings of the paper.
\end{abstract}

\begin{IEEEkeywords}
Artificial Intelligence, LaTeX, Automation, Containerization.
\end{IEEEkeywords}

\section{Introduction}
Modern scientific authoring demands reproducibility, rigorous mathematics, and clean formatting. In this paper, we demonstrate how Antigravity (\texttt{agy}) seamlessly pairs with \LaTeX\ for high-velocity research workflows \cite{sample2024}.

\section{Methodology}
We define our core loss function in Equation~\eqref{eq:loss}:
\begin{equation}
\label{eq:loss}
\mathcal{L}(\theta) = \frac{1}{N} \sum_{i=1}^N \ell(f(x_i; \theta), y_i) + \lambda \|\theta\|_2^2
\end{equation}
where $\theta \in \mathbb{R}^d$ denotes model parameters and $\lambda > 0$ is the regularization coefficient.

\begin{table}[htbp]
\centering
\caption{Comparison of Model Performance}
\label{tab:results}
\begin{tabular}{@{}lccc@{}}
\toprule
\textbf{Model} & \textbf{Precision (\%)} & \textbf{Recall (\%)} & \textbf{F1 Score} \\
\midrule
Baseline       & 84.2                    & 81.0                 & 82.57             \\
Enhanced       & 89.6                    & 88.1                 & 88.84             \\
Proposed (Ours)& \textbf{94.3}           & \textbf{93.8}        & \textbf{94.05}    \\
\bottomrule
\end{tabular}
\end{table}

\section{Conclusion}
We presented a structured framework for LaTeX automation.

\bibliographystyle{IEEEtran}
\bibliography{references}

\end{document}
EOF
        cat << 'EOF' > "$DEST_DIR/references.bib"
@article{sample2024,
  author    = {Turing, Alan and Shannon, Claude},
  title     = {Foundations of Agentic Computing and Scientific Authoring},
  journal   = {Transactions on Computer Science},
  volume    = {42},
  number    = {1},
  pages     = {100--115},
  year      = {2024}
}
EOF
        echo "==> Created Academic Conference Paper template in $DEST_DIR (main.tex, references.bib)."
        ;;

    beamer|presentation|slides)
        cat << 'EOF' > "$DEST_DIR/main.tex"
\documentclass[aspectratio=169]{beamer}
\usetheme{Madrid}
\usecolortheme{default}

\usepackage{amsmath,amssymb}
\usepackage{booktabs}
\usepackage{graphicx}

\title[Short Title]{Full Presentation Title}
\subtitle{Modern Agentic LaTeX Automation}
\author[Author]{Author Name}
\institute[Org]{Department of Computer Science}
\date{\today}

\begin{document}

\begin{frame}
  \titlepage
\end{frame}

\begin{frame}{Table of Contents}
  \tableofcontents
\end{frame}

\section{Motivation}

\begin{frame}{Motivation & Background}
  \begin{itemize}
    \item High-precision scientific typesetting.
    \item Automated compilation with \texttt{latexmk}.
    \item Integrated with Antigravity AI pair programming.
  \end{itemize}

  \pause
  \begin{block}{Key Goal}
    Eliminate compilation overhead while maintaining publication-grade PDF formatting.
  \end{block}
\end{frame}

\section{Mathematical Formulation}

\begin{frame}{Objective Function}
  Given training pairs $(x_i, y_i)$, we optimize:
  \[
    \min_{\theta} \frac{1}{N} \sum_{i=1}^N \| f_\theta(x_i) - y_i \|^2 + \alpha \mathcal{R}(\theta)
  \]
  \begin{alertblock}{Theorem}
    Under mild convexity assumptions, gradient descent converges to global optimum.
  \end{alertblock}
\end{frame}

\section{Conclusion}

\begin{frame}{Summary & Next Steps}
  \begin{columns}
    \begin{column}{0.5\textwidth}
      \textbf{Achievements}:
      \begin{itemize}
        \item Fast multi-pass builds.
        \item Remote SSH / Web IDE.
      \end{itemize}
    \end{column}
    \begin{column}{0.5\textwidth}
      \textbf{Future Directions}:
      \begin{itemize}
        \item Continuous feedback.
        \item Real-time preview.
      \end{itemize}
    \end{column}
  \end{columns}
\end{frame}

\end{document}
EOF
        echo "==> Created Beamer Slides template in $DEST_DIR (main.tex)."
        ;;

    article|*)
        cat << 'EOF' > "$DEST_DIR/main.tex"
\documentclass[11pt,a4paper]{article}

\usepackage[utf8]{inputenc}
\usepackage[margin=1in]{geometry}
\usepackage{amsmath,amssymb,amsthm}
\usepackage{booktabs}
\usepackage{graphicx}
\usepackage{microtype}
\usepackage{hyperref}

\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    citecolor=blue,
    urlcolor=blue
}

\title{Scientific Article Title}
\author{Author Name \\ \texttt{author@example.com}}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
This document serves as a modular starter template for scientific reports and articles.
\end{abstract}

\section{Introduction}
Welcome to LaTeX with Antigravity (`agy`). You can edit this file and compile with:
\begin{verbatim}
latex-compile main.tex
\end{verbatim}

\section{Equations and Tables}
Here is a beautiful equation:
\begin{equation}
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
\end{equation}

\begin{table}[htbp]
\centering
\caption{Sample Table using Booktabs}
\begin{tabular}{llr}
\toprule
\textbf{Item} & \textbf{Category} & \textbf{Score} \\
\midrule
Alpha         & Science           & 9.85           \\
Beta          & Engineering       & 9.42           \\
Gamma         & Mathematics       & 9.91           \\
\bottomrule
\end{tabular}
\end{table}

\section{Conclusion}
Document compiled successfully.

\end{document}
EOF
        echo "==> Created Standard Article template in $DEST_DIR (main.tex)."
        ;;
esac
