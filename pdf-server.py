#!/usr/bin/env python3
"""
High-Performance arXiv-Style Paper Reader Server
Serves both instant responsive HTML papers (arXiv HTML5) and fast Native PDFs
with Dark Mode, Live Auto-Reload, and multi-threaded concurrency.
"""

import os
import sys
import json
import time
import mimetypes
import subprocess
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
import threading

MATHJAX_DIR = "/usr/share/javascript/mathjax"
MIME_OVERRIDES = {
    ".js": "application/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".html": "text/html; charset=utf-8",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".otf": "font/otf",
    ".ttf": "font/ttf",
    ".eot": "application/vnd.ms-fontobject",
    ".svg": "image/svg+xml",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".webp": "image/webp",
}

PORT = int(os.environ.get("PDF_SERVER_PORT", 5000))
WORKSPACE_DIR = os.environ.get("WORKSPACE_DIR", "/home/dev/latex-workspace")
if not os.path.isdir(WORKSPACE_DIR):
    WORKSPACE_DIR = os.environ.get("HOME", "/home/dev")

INDEX_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>arXiv-Style LaTeX Paper Reader</title>
  <style>
    :root {
      --bg: #0f1115;
      --bar-bg: #16181d;
      --border: #262930;
      --text: #e6edf3;
      --text-muted: #8b949e;
      --accent: #58a6ff;
      --btn-bg: #21262d;
      --btn-hover: #30363d;
      --btn-active: #1f6feb;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }
    header {
      background-color: var(--bar-bg);
      border-bottom: 1px solid var(--border);
      padding: 8px 16px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      z-index: 100;
    }
    .header-group {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .brand {
      font-weight: 700;
      font-size: 14px;
      color: var(--accent);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    button, select {
      background-color: var(--btn-bg);
      color: var(--text);
      border: 1px solid var(--border);
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 13px;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
      outline: none;
    }
    button:hover, select:hover {
      background-color: var(--btn-hover);
      border-color: #484f58;
    }
    .btn-active {
      background-color: var(--btn-active) !important;
      border-color: var(--accent) !important;
      color: #fff !important;
    }
    .status-badge {
      font-size: 11px;
      color: #3fb950;
      background: rgba(63, 185, 80, 0.15);
      padding: 3px 8px;
      border-radius: 12px;
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }
    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background-color: #3fb950;
      box-shadow: 0 0 6px #3fb950;
    }
    #frame-container {
      flex: 1;
      width: 100%;
      height: 100%;
      position: relative;
      background-color: var(--bg);
      display: flex;
    }
    #content-frame {
      width: 100%;
      height: 100%;
      border: none;
      background-color: var(--bg);
      transition: filter 0.2s ease;
    }
    /* Dark mode for Native PDF view */
    body.mode-dark.view-pdf #content-frame {
      filter: invert(0.9) hue-rotate(180deg) contrast(0.95);
    }
    body.mode-light.view-pdf #content-frame {
      filter: none;
    }
    body.mode-sepia.view-pdf #content-frame {
      filter: sepia(0.5) contrast(0.95);
    }
    #toast {
      position: fixed;
      bottom: 20px;
      right: 20px;
      background-color: #1f2937;
      color: #f9fafb;
      border: 1px solid #374151;
      padding: 8px 16px;
      border-radius: 6px;
      font-size: 13px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.5);
      opacity: 0;
      transition: opacity 0.3s;
      pointer-events: none;
      z-index: 1000;
    }
    #toast.show { opacity: 1; }
  </style>
</head>
<body class="mode-dark view-html">
  <header>
    <div class="header-group">
      <div class="brand">
        <span>📚</span>
        <span>arXiv Reader</span>
      </div>
      <button id="btn-view-html" class="btn-active" onclick="setViewMode('html')">🌐 arXiv HTML</button>
      <button id="btn-view-pdf" onclick="setViewMode('pdf')">📄 Native PDF</button>
      <select id="file-select" onchange="onFileChange(this.value)"></select>
      <span class="status-badge"><span class="status-dot"></span> Live</span>
    </div>

    <div class="header-group">
      <label style="font-size: 12px; color: var(--text-muted);">Theme:</label>
      <button id="btn-dark" class="btn-active" onclick="setTheme('dark')">🌙 Dark</button>
      <button id="btn-light" onclick="setTheme('light')">☀️ Light</button>
      <button id="btn-sepia" onclick="setTheme('sepia')">📜 Sepia</button>
    </div>

    <div class="header-group">
      <button id="btn-compile" onclick="triggerCompile()">⚡ Recompile</button>
      <button id="btn-download" onclick="downloadCurrent()">⬇ PDF</button>
      <button id="btn-external" onclick="openExternal()" title="Open raw in new tab">↗ New Tab</button>
    </div>
  </header>

  <div id="frame-container">
    <iframe id="content-frame" src="html?file=main.html"></iframe>
  </div>

  <div id="toast">Document reloaded</div>

  <script>
    let currentMode = localStorage.getItem('arxiv_view_mode') || 'html';
    let currentTheme = localStorage.getItem('arxiv_theme') || 'dark';
    let currentFile = 'main.html';
    let availableFiles = [];

    function showToast(msg) {
      const toast = document.getElementById('toast');
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2000);
    }

    function setTheme(theme) {
      currentTheme = theme;
      localStorage.setItem('arxiv_theme', theme);
      document.body.classList.remove('mode-dark', 'mode-light', 'mode-sepia');
      document.body.classList.add('mode-' + theme);
      document.getElementById('btn-dark').classList.toggle('btn-active', theme === 'dark');
      document.getElementById('btn-light').classList.toggle('btn-active', theme === 'light');
      document.getElementById('btn-sepia').classList.toggle('btn-active', theme === 'sepia');

      // Sync theme into iframe if HTML view
      const frame = document.getElementById('content-frame');
      try {
        if (frame.contentWindow && frame.contentWindow.document) {
          frame.contentWindow.document.body.className = 'mode-' + theme;
        }
      } catch (e) {}
    }

    function setViewMode(mode) {
      currentMode = mode;
      localStorage.setItem('arxiv_view_mode', mode);
      document.body.classList.remove('view-html', 'view-pdf');
      document.body.classList.add('view-' + mode);
      document.getElementById('btn-view-html').classList.toggle('btn-active', mode === 'html');
      document.getElementById('btn-view-pdf').classList.toggle('btn-active', mode === 'pdf');
      updateFrame();
    }

    function updateFrame(forceReload = false) {
      const frame = document.getElementById('content-frame');
      const timestamp = forceReload ? '&_t=' + Date.now() : '';
      if (currentMode === 'html') {
        const htmlFile = currentFile.replace(/\\.pdf$/i, '.html');
        frame.src = 'html?file=' + encodeURIComponent(htmlFile) + timestamp;
      } else {
        const pdfFile = currentFile.replace(/\\.html$/i, '.pdf');
        frame.src = 'pdf?file=' + encodeURIComponent(pdfFile) + timestamp;
      }
    }

    async function loadFileList() {
      try {
        const res = await fetch('api/files');
        availableFiles = await res.json();
        const select = document.getElementById('file-select');
        select.innerHTML = '';
        if (availableFiles.length === 0) {
          select.innerHTML = '<option value="main.html">main.html</option>';
          return;
        }
        availableFiles.forEach(f => {
          const opt = document.createElement('option');
          opt.value = f;
          opt.textContent = f;
          select.appendChild(opt);
        });

        if (availableFiles.includes('main.html') || availableFiles.includes('main.pdf')) {
          currentFile = availableFiles.includes('main.html') ? 'main.html' : 'main.pdf';
        } else {
          currentFile = availableFiles[0];
        }
        select.value = currentFile;
        updateFrame();
      } catch (err) {
        console.error('Failed to load file list:', err);
      }
    }

    function onFileChange(file) {
      currentFile = file;
      updateFrame();
    }

    async function triggerCompile() {
      showToast('🔨 Compiling document...');
      try {
        const res = await fetch('api/compile', { method: 'POST' });
        const data = await res.json();
        if (data.success) {
          showToast('✅ Compilation succeeded!');
          updateFrame(true);
        } else {
          showToast('❌ Compilation error: ' + data.error);
        }
      } catch (e) {
        showToast('❌ Compile request failed');
      }
    }

    function downloadCurrent() {
      const pdfFile = currentFile.replace(/\\.html$/i, '.pdf');
      window.open('pdf?file=' + encodeURIComponent(pdfFile) + '&download=1', '_blank');
    }

    function openExternal() {
      if (currentMode === 'html') {
        const htmlFile = currentFile.replace(/\\.pdf$/i, '.html');
        window.open('html?file=' + encodeURIComponent(htmlFile), '_blank');
      } else {
        const pdfFile = currentFile.replace(/\\.html$/i, '.pdf');
        window.open('pdf?file=' + encodeURIComponent(pdfFile), '_blank');
      }
    }

    function setupLiveEvents() {
      const es = new EventSource('events');
      es.onmessage = function(e) {
        if (e.data === 'reload') {
          showToast('⚡ Document updated (Live auto-reload)');
          updateFrame(true);
        }
      };
      es.onerror = function() {
        // Automatically reconnects
      };
    }

    document.getElementById('content-frame').addEventListener('load', function() {
      try {
        const frame = document.getElementById('content-frame');
        if (frame.contentWindow && frame.contentWindow.document) {
          frame.contentWindow.document.body.className = 'mode-' + currentTheme;
        }
      } catch(e) {}
    });

    setTheme(currentTheme);
    setViewMode(currentMode);
    loadFileList();
    setupLiveEvents();
  </script>
</body>
</html>
"""

class ThreadedPDFHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Quiet standard logging to prevent terminal clutter
        pass

    def do_HEAD(self):
        self.do_GET(head_only=True)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        if path.endswith("/api/compile") or path == "/api/compile":
            try:
                cmd = ["/usr/local/bin/latex-compile", "main.tex"]
                res = subprocess.run(cmd, cwd=WORKSPACE_DIR, capture_output=True, text=True, timeout=60)
                if res.returncode == 0:
                    out = json.dumps({"success": True, "message": "Compiled successfully"}).encode("utf-8")
                else:
                    out = json.dumps({"success": False, "error": res.stderr or res.stdout}).encode("utf-8")
            except Exception as e:
                out = json.dumps({"success": False, "error": str(e)}).encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(out)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(out)
        else:
            self.send_error(404, "Endpoint not found")

    def do_GET(self, head_only=False):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # Normalize path
        if path.endswith("/"):
            path = path[:-1]

        if path == "" or path == "/index.html":
            data = INDEX_HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            if not head_only:
                self.wfile.write(data)
            return

        elif path.endswith("/api/files") or path == "/api/files":
            files = []
            if os.path.isdir(WORKSPACE_DIR):
                for root, _, filenames in os.walk(WORKSPACE_DIR):
                    for fn in filenames:
                        if fn.lower().endswith(".pdf") or fn.lower().endswith(".html"):
                            rel = os.path.relpath(os.path.join(root, fn), WORKSPACE_DIR)
                            files.append(rel)
            files.sort()
            data = json.dumps(files).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            if not head_only:
                self.wfile.write(data)
            return

        elif path.endswith("/html") or path == "/html":
            rel_file = query.get("file", ["main.html"])[0]
            clean_rel = os.path.normpath(rel_file).lstrip("/")
            full_path = os.path.join(WORKSPACE_DIR, clean_rel)
            if not full_path.startswith(os.path.abspath(WORKSPACE_DIR)):
                self.send_error(403, "Access denied")
                return

            tex_src = os.path.splitext(full_path)[0] + ".tex"
            needs_build = not os.path.isfile(full_path)
            if not needs_build and os.path.isfile(tex_src):
                try:
                    if os.path.getmtime(tex_src) > os.path.getmtime(full_path):
                        needs_build = True
                    else:
                        with open(full_path, "rb") as f:
                            head_bytes = f.read(16384)
                        if b'/usr/share/javascript/mathjax/MathJax.js"' in head_bytes or b"polyfill.io" in head_bytes:
                            needs_build = True
                except OSError:
                    pass

            if needs_build and os.path.isfile(tex_src) and os.path.exists("/usr/local/bin/latex-to-html"):
                subprocess.run(["/usr/local/bin/latex-to-html", tex_src, full_path], cwd=WORKSPACE_DIR, timeout=30)

            if os.path.isfile(full_path):
                try:
                    with open(full_path, "rb") as f:
                        content = f.read()
                    if b'/usr/share/javascript/mathjax/MathJax.js"' in content:
                        content = content.replace(
                            b'/usr/share/javascript/mathjax/MathJax.js"',
                            b'mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML"'
                        )
                    self.send_response(200)
                    self.send_header("Content-Type", "text/html; charset=utf-8")
                    self.send_header("Content-Length", str(len(content)))
                    self.send_header("Cache-Control", "no-cache, must-revalidate")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.end_headers()
                    if not head_only:
                        self.wfile.write(content)
                except Exception as e:
                    self.send_error(500, f"Error reading file: {e}")
            else:
                self.send_error(404, "HTML paper not found. Click Recompile or run 'latex-compile main.tex'.")
            return

        elif path.endswith("/pdf") or path == "/pdf":
            rel_file = query.get("file", ["main.pdf"])[0]
            clean_rel = os.path.normpath(rel_file).lstrip("/")
            full_path = os.path.join(WORKSPACE_DIR, clean_rel)
            if not full_path.startswith(os.path.abspath(WORKSPACE_DIR)):
                self.send_error(403, "Access denied")
                return

            if not os.path.isfile(full_path):
                tex_src = os.path.splitext(full_path)[0] + ".tex"
                if os.path.isfile(tex_src) and os.path.exists("/usr/local/bin/latex-compile"):
                    subprocess.run(["/usr/local/bin/latex-compile", "-c", tex_src], cwd=WORKSPACE_DIR, timeout=60)

            if os.path.isfile(full_path):
                try:
                    with open(full_path, "rb") as f:
                        content = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/pdf")
                    self.send_header("Content-Length", str(len(content)))
                    if query.get("download", ["0"])[0] == "1":
                        self.send_header("Content-Disposition", f'attachment; filename="{os.path.basename(full_path)}"')
                    else:
                        self.send_header("Content-Disposition", f'inline; filename="{os.path.basename(full_path)}"')
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.send_header("Cache-Control", "no-cache, must-revalidate")
                    self.end_headers()
                    if not head_only:
                        self.wfile.write(content)
                except Exception as e:
                    self.send_error(500, f"Error reading file: {e}")
            else:
                self.send_error(404, "PDF file not found. Click Recompile or run 'latex-compile main.tex'.")
            return

        elif "/mathjax/" in path:
            mj_subpath = path.split("/mathjax/", 1)[1]
            clean_sub = os.path.normpath(mj_subpath).lstrip("/")
            full_path = os.path.abspath(os.path.join(MATHJAX_DIR, clean_sub))
            if not full_path.startswith(os.path.abspath(MATHJAX_DIR)) or not os.path.isfile(full_path):
                self.send_error(404, "MathJax asset not found")
                return
            try:
                with open(full_path, "rb") as f:
                    content = f.read()
                ext = os.path.splitext(full_path)[1].lower()
                ctype = MIME_OVERRIDES.get(ext) or mimetypes.guess_type(full_path)[0] or "application/octet-stream"
                self.send_response(200)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(content)))
                self.send_header("Cache-Control", "public, max-age=86400")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                if not head_only:
                    self.wfile.write(content)
            except Exception as e:
                self.send_error(500, f"Error reading MathJax asset: {e}")
            return

        elif path.endswith("/events") or path == "/events":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            if head_only:
                return

            def get_latest_mtime():
                mtime = 0
                if os.path.isdir(WORKSPACE_DIR):
                    for fn in os.listdir(WORKSPACE_DIR):
                        if fn.endswith((".pdf", ".html", ".tex")):
                            p = os.path.join(WORKSPACE_DIR, fn)
                            try:
                                t = os.path.getmtime(p)
                                if t > mtime:
                                    mtime = t
                            except OSError:
                                pass
                return mtime

            last_mtime = get_latest_mtime()
            try:
                while True:
                    time.sleep(0.5)
                    curr = get_latest_mtime()
                    if curr != last_mtime and curr > 0:
                        last_mtime = curr
                        self.wfile.write(b"data: reload\n\n")
                        self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            return

        else:
            clean_rel = os.path.normpath(path).lstrip("/")
            full_path = os.path.abspath(os.path.join(WORKSPACE_DIR, clean_rel))
            if full_path.startswith(os.path.abspath(WORKSPACE_DIR)) and os.path.isfile(full_path):
                try:
                    with open(full_path, "rb") as f:
                        content = f.read()
                    ext = os.path.splitext(full_path)[1].lower()
                    ctype = MIME_OVERRIDES.get(ext) or mimetypes.guess_type(full_path)[0] or "application/octet-stream"
                    self.send_response(200)
                    self.send_header("Content-Type", ctype)
                    self.send_header("Content-Length", str(len(content)))
                    self.send_header("Cache-Control", "no-cache")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.end_headers()
                    if not head_only:
                        self.wfile.write(content)
                    return
                except Exception:
                    pass
            self.send_error(404, "Endpoint not found")

def run():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), ThreadedPDFHandler)
    server.daemon_threads = True
    print(f"arXiv-Style Paper Reader Server running at http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    run()
