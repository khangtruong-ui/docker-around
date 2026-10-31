# `khangtruong1108/basic:latex` — Autonomous LaTeX, AGY & Remote IDE Environment

[![Docker Pulls](https://img.shields.io/docker/pulls/khangtruong1108/basic)](https://hub.docker.com/r/khangtruong1108/basic)
[![Docker Image Size](https://img.shields.io/docker/image-size/khangtruong1108/basic/latex)](https://hub.docker.com/r/khangtruong1108/basic)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Batteries-included LaTeX engineering and AI-assisted scientific authoring container.
Based on `khangtruong1108/basic:chrome-remote`, extended with a complete **TeX Live compiler suite**, **Antigravity (`agy`) LaTeX skills**, **code-server (Web VS Code)**, **OpenSSH Server for Host IDEs**, **TeXstudio & Evince for Chrome Remote Desktop**, and **pre-configured LaTeX Workshop**.

---

## 🚀 1. Quick Start & Service Ports

Run the container with all services exposed:

```bash
docker run -d \
  --name latex-devbox \
  --privileged \
  -p 2222:22 \
  -p 8443:8443 \
  -p 8888:8888 \
  -p 7681:7681 \
  -e PASSWORD=dev \
  -v latex-data:/home/dev \
  khangtruong1108/basic:latex
```

| Port | Service | Description | Access URL / Command |
| :--- | :--- | :--- | :--- |
| **`8443`** | **code-server** | Full VS Code in Web Browser with LaTeX Workshop & AGY | `http://localhost:8443` (Password: `dev`) |
| **`2222`** | **OpenSSH (`sshd`)** | Connect host VS Code / Cursor via Remote - SSH | `ssh dev@localhost -p 2222` (Password: `dev`) |
| **`8888`** | **JupyterLab** | Interactive notebooks & terminals | `http://localhost:8888` |
| **`7681`** | **ttyd** | Web Terminal for fast terminal agent access | `http://localhost:7681` |
| **CRD** | **Chrome Remote** | Full graphical XFCE Desktop (TeXstudio, Evince) | `https://remotedesktop.google.com` |

---

## 💻 2. Three Ways to Connect Your IDE (Host Remote Control)

### Method A: Web Browser IDE (code-server) — Zero Host Setup
Open `http://localhost:8443` in any browser on your host machine.
- **Pre-installed LaTeX Workshop (`v10.20.0`)**: In-editor PDF preview tab, auto-compilation on save (`onFileChange`), SyncTeX click-to-navigate.
- **Pre-configured Recipes**: Includes `pdfLaTeX (latexmk)`, `XeLaTeX (latexmk)`, and `LuaLaTeX (latexmk)`.
- **Integrated Terminal**: Open the bottom terminal (`Ctrl + \``) inside code-server and run `agy` directly side-by-side with your `.tex` document.
- **Default Password**: `dev` (customizable via `-e PASSWORD=<your_password>`).

### Method B: Host VS Code / Cursor / Windsurf via "Remote - SSH" — Native Host Experience
Use your favorite local host editor while running all builds, LaTeX tools, and agents in the container:
1. Install the official **Remote - SSH** extension (`ms-vscode-remote.remote-ssh`) in your host VS Code or Cursor.
2. In host `~/.ssh/config`, add:
   ```ssh-config
   Host latex-box
       HostName localhost
       Port 2222
       User dev
   ```
3. Connect using `Ctrl+Shift+P` -> `Remote-SSH: Connect to Host...` -> `latex-box` (Password: `dev`).
4. Open the workspace folder: `/home/dev/latex-workspace`.
5. Install extensions into the remote container (e.g. LaTeX Workshop, Antigravity). All TeX Live binaries (`latexmk`, `pdflatex`, `biber`, etc.) and `agy` will be discovered automatically.

### Method C: Chrome Remote Desktop — Full Graphical Desktop
To use native GUI LaTeX tools like **TeXstudio** and **Evince**:
1. Get a headless setup code from [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless).
2. Start the container passing your code and chosen PIN:
   ```bash
   docker run -d \
     --name latex-crd \
     --privileged \
     -p 2222:22 -p 8443:8443 -p 8888:8888 -p 7681:7681 \
     -e CRD_CODE="4/0A..." \
     -e CRD_PIN="123456" \
     khangtruong1108/basic:latex
   ```
3. Connect at [remotedesktop.google.com/access](https://remotedesktop.google.com/access).
4. Launch **TeXstudio** or **Evince** from the desktop shortcuts.

---

## 📄 3. LaTeX Compilers & Helper CLI

The image includes a complete TeX Live setup:
- **Engines**: `pdflatex` (TeX Live 2023), `xelatex`, `lualatex`
- **Automation & Bibliography**: `latexmk` 4.83, `biber` 2.19, `bibtex`
- **Linters & Utilities**: `chktex` 1.7.8, `pygmentize` (for `minted`), `ghostscript`, `qpdf`, `poppler-utils` (`pdfinfo`, `pdftoppm`)
- **Package Suites**: `texlive-latex-base`, `texlive-latex-recommended`, `texlive-latex-extra`, `texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`, `texlive-xetex`, `texlive-luatex`, `texlive-bibtex-extra`, `texlive-publishers` (IEEEtran, ACM sigconf, etc.)

### Included CLI Helper Commands:
These scripts are symlinked directly into `/usr/local/bin` and can be used in any terminal or subagent:

- **`latex-compile [file.tex] [engine]`**: Smart compiler with engine auto-detection, error filtering, and SyncTeX.
  ```bash
  latex-compile main.tex
  ```
- **`latex-clean [dir]`**: Cleans auxiliary build artifacts (`.aux`, `.bbl`, `.fls`, `.log`, `.synctex.gz`, etc.).
  ```bash
  latex-clean
  ```
- **`latex-lint [file.tex]`**: Runs syntax and typography checks via `chktex`.
  ```bash
  latex-lint main.tex
  ```
- **`latex-template [paper|article|slides] [target_dir]`**: Instant starter templates (IEEE conference paper, academic article, or Beamer slides).
  ```bash
  latex-template paper my-paper/
  ```

---

## 🤖 4. Antigravity (`agy`) LaTeX Skill

The `latex` skill is pre-installed globally for `agy` at `/home/dev/.gemini/config/skills/latex` and `/usr/local/share/agy-skills/latex`.

The agent understands:
- Scaffolding IEEE, ACM, Springer, arXiv papers, and Beamer presentations.
- Diagnosing missing LaTeX packages and installing or configuring workarounds.
- Correcting mathematical syntax errors, table layout (`booktabs`), and multi-pass bibliography runs (`biber` / `bibtex`).
- Automated compilation error extraction and correction loops.

### Example Prompts for `agy`:
```bash
agy "Scaffold an IEEE conference paper about agentic AI and compile it to PDF"
agy "Inspect main.log, find the LaTeX compilation error, and fix it"
agy "Convert this plain text table into a professional booktabs LaTeX table"
agy "Add a Beamer presentation summarizing our benchmark results"
```

---

## 📂 5. Repository Layout

```
.
├── Dockerfile                  # Multi-layer Docker recipe extending khangtruong1108/basic:chrome-remote
├── entrypoint.sh               # Multi-service daemon supervisor (code-server, sshd, ttyd, jupyter, CRD)
├── vscode-settings.json        # Pre-configured LaTeX Workshop and code-server settings
├── README.md                   # Comprehensive documentation and reference guide
└── skills/
    └── latex/
        ├── SKILL.md            # AGY skill definition & instructions
        ├── scripts/
        │   ├── compile.sh      # latex-compile: smart compilation script
        │   ├── clean.sh        # latex-clean: auxiliary file removal
        │   ├── lint.sh         # latex-lint: chktex typography linter
        │   └── template.sh     # latex-template: project scaffolding
        └── references/
            ├── compilation.md  # TeX engine selection & build options
            ├── troubleshooting.md # Compilation error dictionary & fixes
            └── best_practices.md # Typesetting guidelines, bibliography, and booktabs
```

---

## 🔐 Credentials & Default Logins

| Service | Username | Default Password | Environment Override |
| :--- | :--- | :--- | :--- |
| **code-server (Web IDE)** | `dev` | `dev` | `PASSWORD=<secret>` |
| **SSH** | `dev` | `dev` | Passwordless `sudo` & `docker` group |
| **SSH (root)** | `root` | `root` | Full root access |
| **JupyterLab** | - | *(No token / password)* | `JUPYTER_TOKEN=<secret>` |
| **Chrome Remote Desktop** | `dev` | PIN set in `CRD_PIN` | `CRD_CODE` & `CRD_PIN` |

---

## 📄 License
MIT License. Free for academic, personal, and commercial development.
