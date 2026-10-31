# `khangtruong1108/basic:latex` — Autonomous LaTeX, AGY & Remote IDE Environment

[![Docker Pulls](https://img.shields.io/docker/pulls/khangtruong1108/basic)](https://hub.docker.com/r/khangtruong1108/basic)
[![Docker Image Size](https://img.shields.io/docker/image-size/khangtruong1108/basic/latex)](https://hub.docker.com/r/khangtruong1108/basic)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Batteries-included LaTeX engineering and AI-assisted scientific authoring container.
Based on `khangtruong1108/basic:chrome-remote`, extended with a complete **TeX Live compiler suite**, **Antigravity (`agy`) LaTeX skills**, **code-server (Web VS Code IDE)**, **Dark Mode PDF Viewers (both in-editor and standalone live web app)**, **OpenSSH Server for Host IDEs**, **TeXstudio & Evince for Chrome Remote Desktop**, and **pre-configured LaTeX Workshop**.

---

## 🚀 1. Quick Start & Service Ports

Run the container with all services exposed (formatted as a single line for Windows Terminal, PowerShell, CMD, and Linux/macOS):

```bash
docker run -d --name latex-devbox --privileged -p 2222:22 -p 8443:8443 -p 5000:5000 -p 8888:8888 -p 7681:7681 -e PASSWORD=dev -v latex-data:/home/dev/latex-workspace khangtruong1108/basic:latex
```

> **Windows Terminal / PowerShell / CMD Note**: Commands are formatted on a single line so they run immediately without multi-line backslash (`\`) syntax errors.

| Port | Service | Description | Access URL / Command |
| :--- | :--- | :--- | :--- |
| **`8443`** | **code-server (Web IDE)** | Web LaTeX editor with LaTeX Workshop, Magic PDF & AGY | `http://localhost:8443` (Password: `dev`) |
| **`5000`** | **Live Dark Mode PDF Viewer** | Standalone web reader with live auto-reload & dark mode | `http://localhost:5000` or `http://localhost:8443/proxy/5000/` |
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
The web editor opens straight into `/home/dev/latex-workspace`, pre-loaded with a sample IEEE conference paper (`main.tex`, `references.bib`):
1. **Open `main.tex`** from the left file explorer.
2. **Auto-Compilation on Save**:
   - Edit your text or math and press <kbd>Ctrl</kbd>+<kbd>S</kbd> (<kbd>Cmd</kbd>+<kbd>S</kbd>). LaTeX Workshop automatically invokes `latexmk` with SyncTeX and updates `main.pdf`.
   - Alternatively, press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>B</kbd> to trigger a manual build recipe (`pdfLaTeX`, `XeLaTeX`, or `LuaLaTeX`).
3. **Integrated Terminal & AGY Pair Programming**:
   - Press <kbd>Ctrl</kbd>+<kbd>`</kbd> (or go to **Menu ➔ Terminal ➔ New Terminal**) inside the browser IDE to open the bottom terminal.
   - Run AI assistance commands right alongside your `.tex` document:
     ```bash
     agy -i "Make the pdf at least 2 pages long and fix references"
     ```
     *(Or run `agy` to enter the interactive chat interface, or `agy -p "..."` for batch mode).*
   - Run helper commands:
     ```bash
     latex-compile main.tex   # Compiles with smart engine detection
     latex-lint main.tex      # Typography and syntax check (chktex)
     latex-clean              # Cleans auxiliary build artifacts
     ```

---

## 📖 3. How to View PDFs (Dark Mode Supported)

Viewing PDFs in browser-based VS Code previously suffered from infinite loading due to internal loopback port forwarding limits. This image provides **two robust viewing solutions**, both featuring **Dark Mode by default**:

### Method A: Inside Web VS Code (Magic PDF Custom Editor)
- **Zero-Latency In-Editor Tab**: Click any `.pdf` (such as `main.pdf`) in the VS Code file explorer, or press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd>.
- **Instant Opening**: Uses the pre-installed `els4nta.vscode-magic-pdf` extension running entirely inside the webview sandbox—no dynamic loopback port issues or endless loading spinners.
- **Dark Mode by Default**: PDFs open with a `#1e1e1e` dark canvas and inverted typography for comfortable night reading.
- **Auto-Sync**: Automatically refreshes whenever you save (<kbd>Ctrl</kbd>+<kbd>S</kbd>) and recompile.
- **Controls**: Includes zoom, page outline bookmarks, and a top-bar button to toggle between Dark Mode, Light Mode, and Page Color Inversion.

### Method B: Standalone Live Dark Mode PDF Web App (Port 5000)
A dedicated, lightweight web reader runs in the background on port `5000`:
- **Direct Access**: Open **`http://localhost:5000`** in your host browser (side-by-side with your editor or on a second monitor).
- **Access via code-server Proxy**: If port 5000 is not exposed to the host, open **`http://localhost:8443/proxy/5000/`** directly through code-server's built-in reverse proxy (no extra ports required!).
- **Inside VS Code**: Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> ➔ `Simple Browser: Show` ➔ enter `http://localhost:8443/proxy/5000/` to dock the live reader right in a split tab.
- **Features**:
  - 🌙 **Dark Mode (Default)**, ☀️ **Light Mode**, and 📜 **Sepia** one-click toggles.
  - ⚡ **Live Auto-Reload (SSE)**: Automatically detects when `main.pdf` is recompiled and re-renders instantly while preserving your scroll position.
  - 🔍 **Zoom & Fit**: Fit Width, Fit Page, 75%, 100%, 150%, 200%.
  - 📑 **Workspace Dropdown**: Seamlessly switch between any `.pdf` file in `/home/dev/latex-workspace`.
  - ⬇ **One-Click Download**: Direct PDF export.

CLI management commands inside any container terminal:
```bash
latex-preview status   # Inspects PDF server status
latex-preview restart  # Restarts the standalone reader service
latex-preview logs     # Views live server logs
```

---

## 🖥️ 4. Other Host Remote Control Options

### Option B: Host VS Code / Cursor via "Remote - SSH"
Use your native desktop editor while running compilers and tools inside the container:
1. In host `~/.ssh/config` (or `%USERPROFILE%\.ssh\config` on Windows), add:
   ```ssh-config
   Host latex-box
       HostName localhost
       Port 2222
       User dev
   ```
2. In host VS Code, install **Remote - SSH**, press `F1` ➔ `Remote-SSH: Connect to Host...` ➔ select `latex-box` (password: `dev`).
3. Open `/home/dev/latex-workspace`.

### Option C: Google Chrome Remote Desktop (Full XFCE Desktop GUI)
For full GUI tools like **TeXstudio** and **Evince**:
1. Run with CRD credentials:
   ```bash
   docker run -d --name latex-crd --privileged --shm-size=2g -p 2222:22 -p 8443:8443 -p 5000:5000 -p 8888:8888 -p 7681:7681 -e PASSWORD=dev -e CRD_CODE="<auth_code>" -e CRD_PIN="123456" khangtruong1108/basic:latex
   ```
2. Connect at [remotedesktop.google.com/access](https://remotedesktop.google.com/access).
3. Launch **TeXstudio** or **Evince** from the desktop shortcuts.

---

## 📄 5. LaTeX Compilers & Helper CLI

The image includes a complete TeX Live setup:
- **Engines**: `pdflatex` (TeX Live 2023), `xelatex`, `lualatex`
- **Automation & Bibliography**: `latexmk` 4.83, `biber` 2.19, `bibtex`
- **Linters & Utilities**: `chktex` 1.7.8, `pygmentize` (for `minted`), `ghostscript`, `qpdf`, `poppler-utils` (`pdfinfo`, `pdftoppm`)
- **Package Suites**: `texlive-latex-base`, `texlive-latex-recommended`, `texlive-latex-extra`, `texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`, `texlive-xetex`, `texlive-luatex`, `texlive-bibtex-extra`, `texlive-publishers` (IEEEtran, ACM sigconf, etc.)

### Included CLI Helper Commands:
These scripts are symlinked directly into `/usr/local/bin` and can be used in any terminal or subagent:

- **`latex-compile [file.tex] [engine]`**: Smart compiler with engine auto-detection, error filtering, and SyncTeX:
  ```bash
  latex-compile main.tex
  ```
- **`latex-clean [dir]`**: Cleans auxiliary build artifacts (`.aux`, `.bbl`, `.fls`, `.log`, `.synctex.gz`, etc.):
  ```bash
  latex-clean
  ```
- **`latex-lint [file.tex]`**: Runs syntax and typography checks via `chktex`:
  ```bash
  latex-lint main.tex
  ```
- **`latex-template [paper|article|slides] [target_dir]`**: Instant starter templates (IEEE conference paper, academic article, or Beamer slides):
  ```bash
  latex-template paper my-paper/
  ```
- **`latex-preview [status|restart|logs]`**: Standalone live dark-mode PDF reader controller:
  ```bash
  latex-preview
  ```

---

## 🤖 6. Antigravity (`agy`) LaTeX Skill

The `latex` skill is pre-installed globally for `agy` at `/home/dev/.agents/skills/latex` and `/home/dev/.gemini/config/skills/latex`.

### Example Usage with `agy`:

You can start an interactive AI session with a prompt using `agy -i "..."`, run in batch print mode with `agy -p "..."`, or just launch `agy`:

```bash
# Interactive mode with an initial prompt:
agy -i "Scaffold an IEEE conference paper about agentic AI and compile it to PDF"
agy -i "Inspect main.log, find the LaTeX compilation error, and fix it"

# Batch / print mode:
agy -p "Convert this plain text table into a professional booktabs LaTeX table"

# Or launch the full interactive assistant:
agy
```

---

## 📂 7. Repository Layout

```
.
├── Dockerfile                  # Multi-layer Docker recipe extending khangtruong1108/basic:chrome-remote
├── entrypoint.sh               # Multi-service daemon supervisor (code-server, pdf-server, sshd, ttyd, jupyter, CRD)
├── pdf-server.py               # Standalone Dark Mode PDF reader & SSE live auto-reload server
├── latex-preview.sh            # CLI controller for the live PDF reader (latex-preview / pdf-view)
├── web-ide.sh                  # CLI controller for code-server Web IDE (web-ide / latex-editor)
├── vscode-settings.json        # Pre-configured LaTeX Workshop and Dark Mode Magic PDF settings
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
| **Dark Mode PDF Reader** | - | *(No login required)* | `http://localhost:5000` |
| **SSH** | `dev` | `dev` | Passwordless `sudo` & `docker` group |
| **SSH (root)** | `root` | `root` | Full root access |
| **JupyterLab** | - | *(No token / password)* | `JUPYTER_TOKEN=<secret>` |
| **Chrome Remote Desktop** | `dev` | PIN set in `CRD_PIN` | `CRD_CODE` & `CRD_PIN` |

---

## 📄 License
MIT License. Free for academic, personal, and commercial development.
