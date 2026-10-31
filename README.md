# `khangtruong1108/basic:latex` — Autonomous LaTeX, AGY & Remote IDE Environment

[![Docker Pulls](https://img.shields.io/docker/pulls/khangtruong1108/basic)](https://hub.docker.com/r/khangtruong1108/basic)
[![Docker Image Size](https://img.shields.io/docker/image-size/khangtruong1108/basic/latex)](https://hub.docker.com/r/khangtruong1108/basic)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Batteries-included LaTeX engineering and AI-assisted scientific authoring container.
Based on `khangtruong1108/basic:chrome-remote`, extended with a complete **TeX Live compiler suite**, **Antigravity (`agy`) LaTeX skills**, **code-server (Web VS Code IDE)**, **arXiv-Style Paper Reader (Instant HTML & Native PDF with Dark Mode)**, **OpenSSH Server for Host IDEs**, **TeXstudio & Evince for Chrome Remote Desktop**, and **pre-configured LaTeX Workshop**.

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
| **`5000`** | **arXiv-Style Paper Reader** | Instant arXiv HTML (<10ms) & Fast Native PDF in Dark Mode | `http://localhost:5000` or `http://localhost:8443/proxy/5000/` |
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
The web editor opens straight into `/home/dev/latex-workspace`, pre-loaded with a starter IEEE conference paper (`main.tex`, `references.bib`):
1. **Open `main.tex`** from the left file explorer.
2. **Auto-Compilation on Save**:
   - Edit your text or math and press <kbd>Ctrl</kbd>+<kbd>S</kbd> (<kbd>Cmd</kbd>+<kbd>S</kbd>). LaTeX Workshop invokes `latexmk` and automatically updates both `main.pdf` and `main.html`.
   - Alternatively, press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>B</kbd> to trigger a manual build recipe (`pdfLaTeX`, `XeLaTeX`, or `LuaLaTeX`).
3. **Integrated Terminal & AGY Pair Programming**:
   - Press <kbd>Ctrl</kbd>+<kbd>`</kbd> (or go to **Menu ➔ Terminal ➔ New Terminal**) inside the browser IDE to open the bottom terminal.
   - Run AI assistance commands right alongside your `.tex` document using `-i` (interactive) or `-p` (print mode):
     ```bash
     agy -i "Make the pdf at least 2 pages long and fix references"
     ```
     *(Or simply run `agy` to enter the interactive chat interface).*
   - Run helper commands:
     ```bash
     latex-compile main.tex   # Compiles both main.pdf AND arXiv-style main.html
     latex-to-html main.tex   # Converts LaTeX to responsive HTML with MathJax
     latex-lint main.tex      # Typography and syntax check (chktex)
     latex-clean              # Cleans auxiliary build artifacts
     ```

---

## ⚡ 3. High-Speed Paper Reading (arXiv-Style HTML & Native PDF)

Viewing PDFs inside web-based VS Code previously hung due to single-threaded proxy limits and client-side PDF.js overhead. This container solves it by adopting **the arXiv rendering model**:

### How arXiv Renders Documents Fast
1. **arXiv HTML Mode (ar5iv)**: Rather than parsing raw binary PDF streams in JavaScript, arXiv compiles LaTeX into semantic, responsive **HTML5 + MathJax** (`http://localhost:5000/html?file=main.html`). It renders in **< 10ms**, reflows perfectly across all screen sizes, and is natively styled in Dark Mode.
2. **Native C++ PDF Streaming**: arXiv streams PDFs directly with `Content-Type: application/pdf; Content-Disposition: inline`. This bypasses heavy JavaScript and delegates rendering to the browser's hardware-accelerated C++ PDF engine (Chromium PDFium / Firefox Gecko).

---

### Reading Options Available

#### Option A: arXiv-Style Web Reader Dashboard (Port 5000 or Proxy)
- **Direct Access**: 👉 **`http://localhost:5000`**
- **Via code-server Proxy**: 👉 **`http://localhost:8443/proxy/5000/`** (No extra ports required!)
- **Docked inside VS Code**: In code-server, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> ➔ `Simple Browser: Show` ➔ enter `http://localhost:8443/proxy/5000/` to dock the live reader side-by-side with your code!
- **Features**:
  - 🌐 **arXiv HTML Mode**: Instant reflowable HTML5 paper with crisp MathJax equations.
  - 📄 **Native Fast PDF Mode**: Direct hardware-accelerated PDF rendering with Dark Mode filter.
  - 🌙 **Dark Mode (Default)**, ☀️ **Light Mode**, and 📜 **Sepia** one-click toggles.
  - ⚡ **Live Auto-Reload (Multi-Threaded SSE)**: Updates immediately whenever you save or compile without blocking HTTP traffic or losing your scroll position.
  - 🔨 **Recompile Button**: Click `⚡ Recompile` in the toolbar to build without touching a terminal.
  - ⬇ **One-Click Download**: Instant PDF export.

#### Option B: Direct Raw URLs (Fastest Possible)
- **Raw arXiv HTML Paper**: `http://localhost:5000/html?file=main.html` (renders in < 10ms)
- **Raw Native PDF Stream**: `http://localhost:5000/pdf?file=main.pdf` (native browser PDFium engine)

#### Option C: In-Editor VS Code Magic PDF Tab
- In code-server, click `main.pdf` or press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd>.
- Opens the custom editor tab with dark theme (`#1e1e1e`) without opening dynamic loopback ports.

---

### CLI Helper Commands Inside the Container

Manage papers and reader services from any container shell:
```bash
latex-compile main.tex   # Compiles both camera-ready PDF and arXiv HTML
latex-to-html main.tex   # Generates standalone arXiv HTML5 paper with MathJax
latex-preview status     # Inspects reader status
latex-preview restart    # Restarts the multi-threaded reader service
latex-preview logs       # Views real-time server logs
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
- **Converters & HTML**: `pandoc` 3.1, `libjs-mathjax` (offline MathJax display engine), `pdftohtml`
- **Linters & Utilities**: `chktex` 1.7.8, `pygmentize` (for `minted`), `ghostscript`, `qpdf`, `poppler-utils` (`pdfinfo`, `pdftoppm`)
- **Package Suites**: `texlive-latex-base`, `texlive-latex-recommended`, `texlive-latex-extra`, `texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`, `texlive-xetex`, `texlive-luatex`, `texlive-bibtex-extra`, `texlive-publishers` (IEEEtran, ACM sigconf, etc.)

---

## 🤖 6. Antigravity (`agy`) LaTeX Skill

The `latex` skill is pre-installed globally for `agy` at `/home/dev/.agents/skills/latex` and `/home/dev/.gemini/config/skills/latex`.

### Example Usage with `agy`:
```bash
# Interactive mode with an initial prompt:
agy -i "Scaffold an IEEE conference paper about agentic AI and compile it to PDF and HTML"
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
├── pdf-server.py               # arXiv-style paper reader (HTML5 + MathJax & native PDF with Dark Mode & threaded SSE)
├── latex-preview.sh            # CLI controller for the live paper reader (latex-preview / pdf-view)
├── web-ide.sh                  # CLI controller for code-server Web IDE (web-ide / latex-editor)
├── arxiv-theme.css             # Academic dark theme CSS for responsive HTML papers
├── vscode-settings.json        # Pre-configured LaTeX Workshop and Dark Mode Magic PDF settings
├── README.md                   # Comprehensive documentation and reference guide
└── skills/
    └── latex/
        ├── SKILL.md            # AGY skill definition & instructions
        ├── scripts/
        │   ├── compile.sh      # latex-compile: smart compilation script (builds PDF + HTML)
        │   ├── to-html.sh      # latex-to-html: converts LaTeX to responsive HTML5 + MathJax
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
| **arXiv Paper Reader** | - | *(No login required)* | `http://localhost:5000` |
| **SSH** | `dev` | `dev` | Passwordless `sudo` & `docker` group |
| **SSH (root)** | `root` | `root` | Full root access |
| **JupyterLab** | - | *(No token / password)* | `JUPYTER_TOKEN=<secret>` |
| **Chrome Remote Desktop** | `dev` | PIN set in `CRD_PIN` | `CRD_CODE` & `CRD_PIN` |

---

## 📄 License
MIT License. Free for academic, personal, and commercial development.
