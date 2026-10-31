# `khangtruong1108/basic:latex` — Autonomous LaTeX, AGY & Remote IDE Environment

[![Docker Pulls](https://img.shields.io/docker/pulls/khangtruong1108/basic)](https://hub.docker.com/r/khangtruong1108/basic)
[![Docker Image Size](https://img.shields.io/docker/image-size/khangtruong1108/basic/latex)](https://hub.docker.com/r/khangtruong1108/basic)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Batteries-included LaTeX engineering and AI-assisted scientific authoring container.
Based on `khangtruong1108/basic:chrome-remote`, extended with a complete **TeX Live compiler suite**, **Antigravity (`agy`) LaTeX skills**, **code-server (Web VS Code IDE)**, **OpenSSH Server for Host IDEs**, **TeXstudio & Evince for Chrome Remote Desktop**, and **pre-configured LaTeX Workshop**.

---

## 🚀 1. Quick Start & Service Ports

Run the container with all services exposed (formatted as a single line for Windows Terminal, PowerShell, CMD, and Linux/macOS):

```bash
docker run -d --name latex-devbox --privileged -p 2222:22 -p 8443:8443 -p 8888:8888 -p 7681:7681 -e PASSWORD=dev -v latex-data:/home/dev/latex-workspace khangtruong1108/basic:latex
```

> **Windows Terminal / PowerShell / CMD Note**: Commands are formatted on a single line so they run immediately without multi-line backslash (`\`) syntax errors.

| Port | Service | Description | Access URL / Command |
| :--- | :--- | :--- | :--- |
| **`8443`** | **code-server (Web IDE)** | Web LaTeX editor with LaTeX Workshop, SyncTeX & AGY | `http://localhost:8443` (Password: `dev`) |
| **`2222`** | **OpenSSH (`sshd`)** | Connect host VS Code / Cursor via Remote - SSH | `ssh dev@localhost -p 2222` (Password: `dev`) |
| **`8888`** | **JupyterLab** | Interactive notebooks & terminals | `http://localhost:8888` |
| **`7681`** | **ttyd** | Web Terminal for fast terminal agent access | `http://localhost:7681` |
| **CRD** | **Chrome Remote** | Full graphical XFCE Desktop (TeXstudio, Evince) | `https://remotedesktop.google.com` |

---

## 💻 2. How to Use the Remote LaTeX Editor (code-server)

### Step 1: Open the Web LaTeX Editor
Once the container is running, open your web browser on your host machine:
👉 **`http://localhost:8443`**

### Step 2: Log In
When prompted for a password, enter:
- Default Password: **`dev`**
- *(Customizable when starting the container via `-e PASSWORD=<your_password>` or disabled entirely via `-e CODE_SERVER_AUTH=none`)*.

### Step 3: Edit and Typeset Your Documents
The web editor opens straight into `/home/dev/latex-workspace`, pre-loaded with sample IEEE papers (`main.tex`, `references.bib`):
1. **Open `main.tex`** from the left file explorer.
2. **Synchronized PDF Preview**:
   - Click the **"View LaTeX PDF"** tab icon in the editor's top-right toolbar (or press `Ctrl+Alt+V`).
   - A live, in-browser PDF preview tab opens side-by-side with your LaTeX source code.
3. **Auto-Compilation on Save**:
   - Simply edit your text or math and press `Ctrl+S` (`Cmd+S`). LaTeX Workshop automatically invokes `latexmk` with SyncTeX and refreshes the PDF preview tab instantly.
   - Alternatively, press `Ctrl+Alt+B` to trigger a manual build recipe (`pdfLaTeX`, `XeLaTeX`, or `LuaLaTeX`).
4. **SyncTeX Jump (Code ↔ PDF)**:
   - `Ctrl + click` anywhere in the PDF preview tab to jump directly to the corresponding line in `main.tex`.
   - Click "SyncTeX to cursor" in the editor tab to jump to the matching page in the PDF preview.
5. **Integrated Terminal & AGY Pair Programming**:
   - Press `Ctrl + \`` inside the browser IDE to open the bottom terminal.
   - Run AI assistance commands right alongside your `.tex` document:
     ```bash
     agy "Fix any equation or reference issues in main.tex and recompile"
     ```
   - Run helper commands:
     ```bash
     latex-compile main.tex   # Compiles with smart engine detection
     latex-lint main.tex      # Typography and syntax check (chktex)
     latex-clean              # Cleans auxiliary build artifacts
     ```
6. **In-Container Web IDE Helper**:
   - Inside any container shell, run `web-ide` or `latex-editor` to inspect service status or restart code-server.

---

## 🖥️ 3. Other Host Remote Control Options

### Option B: Host VS Code / Cursor via "Remote - SSH"
Use your native desktop editor while running compilers and tools inside the container:
1. In host `~/.ssh/config` (or `%USERPROFILE%\.ssh\config` on Windows), add:
   ```ssh-config
   Host latex-box
       HostName localhost
       Port 2222
       User dev
   ```
2. In VS Code or Cursor: press `Ctrl+Shift+P` -> `Remote-SSH: Connect to Host...` -> `latex-box` (Password: `dev`).
3. Open folder: `/home/dev/latex-workspace`. All compilers (`latexmk`, `pdflatex`, `biber`) and `agy` work natively.

### Option C: Chrome Remote Desktop — Full Graphical Desktop
For native GUI LaTeX applications (**TeXstudio** and **Evince**):
1. Obtain an auth code from [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless).
2. Start the container with your code (single line for Windows Terminal / PowerShell):
   ```bash
   docker run -d --name latex-crd --privileged -p 2222:22 -p 8443:8443 -p 8888:8888 -p 7681:7681 -e CRD_CODE="4/0A..." -e CRD_PIN="123456" khangtruong1108/basic:latex
   ```
3. Connect at [remotedesktop.google.com/access](https://remotedesktop.google.com/access).
4. Launch **TeXstudio** or **Evince** directly from desktop icons.

---

## 📄 4. LaTeX Compilers & Helper CLI

The image includes a complete TeX Live setup:
- **Engines**: `pdflatex` (TeX Live 2023), `xelatex`, `lualatex`
- **Automation & Bibliography**: `latexmk` 4.83, `biber` 2.19, `bibtex`
- **Linters & Utilities**: `chktex` 1.7.8, `pygmentize` (for `minted`), `ghostscript`, `qpdf`, `poppler-utils` (`pdfinfo`, `pdftoppm`)
- **Package Suites**: `texlive-latex-base`, `texlive-latex-recommended`, `texlive-latex-extra`, `texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`, `texlive-xetex`, `texlive-luatex`, `texlive-bibtex-extra`, `texlive-publishers` (IEEEtran, ACM sigconf, etc.)

### Included CLI Commands:
- `latex-compile [file.tex] [engine]` — Smart compiler with engine detection and error filtering.
- `latex-clean [dir]` — Cleans auxiliary build artifacts (`.aux`, `.bbl`, `.fls`, `.log`, `.synctex.gz`).
- `latex-lint [file.tex]` — Runs typography and syntax checks via `chktex`.
- `latex-template [paper|article|slides] [dir]` — Scaffolds instant starter templates (IEEE paper, academic article, or Beamer slides).
- `web-ide` (or `latex-editor`) — Checks or restarts code-server Web IDE.

---

## 🤖 5. Antigravity (`agy`) LaTeX Skill

The `latex` skill is pre-installed globally for `agy` at `/home/dev/.agents/skills/latex` and `/home/dev/.gemini/config/skills/latex`.

### Example Prompts for `agy`:
```bash
agy "Scaffold an IEEE conference paper about agentic AI and compile it to PDF"
agy "Inspect main.log, find the LaTeX compilation error, and fix it"
agy "Convert this plain text table into a professional booktabs LaTeX table"
agy "Add a Beamer presentation summarizing our benchmark results"
```

---

## 📂 6. Repository Layout

```
.
├── Dockerfile                  # Multi-layer Docker recipe extending khangtruong1108/basic:chrome-remote
├── entrypoint.sh               # Multi-service daemon supervisor (code-server, sshd, ttyd, jupyter, CRD)
├── web-ide.sh                  # CLI helper for web IDE status & startup
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
| **code-server (Web IDE)** | `dev` | `dev` | `PASSWORD=<secret>` or `CODE_SERVER_AUTH=none` |
| **SSH** | `dev` | `dev` | Passwordless `sudo` & `docker` group |
| **SSH (root)** | `root` | `root` | Full root access |
| **JupyterLab** | - | *(No token / password)* | `JUPYTER_TOKEN=<secret>` |
| **Chrome Remote Desktop** | `dev` | PIN set in `CRD_PIN` | `CRD_CODE` & `CRD_PIN` |

---

## 📄 License
MIT License. Free for academic, personal, and commercial development.
