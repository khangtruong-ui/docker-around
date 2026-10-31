#!/usr/bin/env python3
"""
Lightweight, zero-dependency Dark Mode PDF Viewer & Live Auto-Reload Server
Designed for code-server proxy and standalone browser usage.
"""

import os
import sys
import json
import time
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

PORT = int(os.environ.get("PDF_SERVER_PORT", 5000))
WORKSPACE_DIR = os.environ.get("WORKSPACE_DIR", "/home/dev/latex-workspace")
if not os.path.isdir(WORKSPACE_DIR):
    WORKSPACE_DIR = os.environ.get("HOME", "/home/dev")

STATIC_DIR = "/usr/local/share/pdf-viewer"

INDEX_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LaTeX Dark Mode PDF Viewer</title>
  <script src="static/pdf.min.js"></script>
  <style>
    :root {
      --bg-color: #121214;
      --bar-bg: #18181b;
      --border-color: #27272a;
      --text-color: #e4e4e7;
      --text-muted: #a1a1aa;
      --btn-bg: #27272a;
      --btn-hover: #3f3f46;
      --btn-active: #52525b;
      --accent-color: #3b82f6;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      background-color: var(--bg-color);
      color: var(--text-color);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      overflow-x: hidden;
      display: flex;
      flex-direction: column;
      height: 100vh;
    }
    header {
      position: sticky;
      top: 0;
      z-index: 1000;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 8px 16px;
      background-color: var(--bar-bg);
      border-bottom: 1px solid var(--border-color);
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.4);
    }
    .header-group {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .title-badge {
      display: flex;
      align-items: center;
      gap: 6px;
      font-weight: 600;
      font-size: 14px;
      color: #60a5fa;
    }
    select, button, input {
      background-color: var(--btn-bg);
      color: var(--text-color);
      border: 1px solid var(--border-color);
      padding: 5px 10px;
      border-radius: 6px;
      font-size: 13px;
      cursor: pointer;
      outline: none;
      transition: background 0.15s, border-color 0.15s;
    }
    select:hover, button:hover {
      background-color: var(--btn-hover);
      border-color: #52525b;
    }
    button:active {
      background-color: var(--btn-active);
    }
    .btn-active {
      background-color: #2563eb !important;
      border-color: #3b82f6 !important;
      color: #fff !important;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 12px;
      color: #10b981;
      padding: 2px 8px;
      border-radius: 12px;
      background: rgba(16, 185, 129, 0.1);
    }
    .status-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background-color: #10b981;
      box-shadow: 0 0 8px #10b981;
    }
    #viewer-container {
      flex: 1;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px 10px;
      gap: 20px;
    }
    .page-wrapper {
      position: relative;
      display: flex;
      justify-content: center;
      transition: filter 0.2s ease;
    }
    canvas {
      display: block;
      border-radius: 4px;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
    }
    /* Theme Modes */
    body.mode-dark canvas {
      filter: invert(0.9) hue-rotate(180deg) contrast(0.95);
    }
    body.mode-light canvas {
      filter: none;
    }
    body.mode-sepia canvas {
      filter: sepia(0.5) contrast(0.95);
    }
    #empty-state {
      margin-top: 100px;
      text-align: center;
      color: var(--text-muted);
    }
    #toast {
      position: fixed;
      bottom: 20px;
      right: 20px;
      background-color: #1e293b;
      color: #f8fafc;
      border: 1px solid #334155;
      padding: 8px 16px;
      border-radius: 6px;
      font-size: 13px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.5);
      opacity: 0;
      transition: opacity 0.3s;
      pointer-events: none;
      z-index: 2000;
    }
    #toast.show { opacity: 1; }
  </style>
</head>
<body class="mode-dark">
  <header>
    <div class="header-group">
      <div class="title-badge">
        <span>📄</span>
        <span>LaTeX Reader</span>
      </div>
      <select id="file-select" title="Select PDF"></select>
      <button id="btn-refresh" title="Manual Reload">↻ Reload</button>
      <span class="status-badge" id="live-indicator"><span class="status-dot"></span> Live</span>
    </div>

    <div class="header-group">
      <label style="font-size: 12px; color: var(--text-muted);">Theme:</label>
      <button id="btn-dark" class="btn-active" onclick="setTheme('dark')">🌙 Dark</button>
      <button id="btn-light" onclick="setTheme('light')">☀️ Light</button>
      <button id="btn-sepia" onclick="setTheme('sepia')">📜 Sepia</button>
    </div>

    <div class="header-group">
      <button id="btn-zoom-out" title="Zoom Out">−</button>
      <select id="zoom-select" onchange="onZoomChange(this.value)">
        <option value="auto">Auto Fit</option>
        <option value="page-width" selected>Fit Width</option>
        <option value="0.75">75%</option>
        <option value="1.0">100%</option>
        <option value="1.25">125%</option>
        <option value="1.5">150%</option>
        <option value="2.0">200%</option>
      </select>
      <button id="btn-zoom-in" title="Zoom In">+</button>
      <button id="btn-download" title="Download PDF">⬇ Download</button>
    </div>
  </header>

  <div id="viewer-container">
    <div id="empty-state">Loading PDF...</div>
  </div>

  <div id="toast">PDF reloaded</div>

  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'static/pdf.worker.min.js';

    let currentPdfDoc = null;
    let currentScale = 'page-width';
    let currentFile = '';
    let eventSource = null;

    function showToast(msg) {
      const toast = document.getElementById('toast');
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2000);
    }

    function setTheme(mode) {
      document.body.className = 'mode-' + mode;
      document.getElementById('btn-dark').classList.toggle('btn-active', mode === 'dark');
      document.getElementById('btn-light').classList.toggle('btn-active', mode === 'light');
      document.getElementById('btn-sepia').classList.toggle('btn-active', mode === 'sepia');
      localStorage.setItem('latex_pdf_theme', mode);
    }

    // Restore saved theme
    const savedTheme = localStorage.getItem('latex_pdf_theme') || 'dark';
    setTheme(savedTheme);

    async function loadFileList() {
      try {
        const res = await fetch('api/files');
        const files = await res.json();
        const select = document.getElementById('file-select');
        select.innerHTML = '';
        if (files.length === 0) {
          select.innerHTML = '<option value="">(No PDF found)</option>';
          document.getElementById('empty-state').textContent = 'No PDF file found. Run "latex-compile main.tex" to compile.';
          return;
        }
        files.forEach(f => {
          const opt = document.createElement('option');
          opt.value = f;
          opt.textContent = f;
          select.appendChild(opt);
        });

        // Default to main.pdf if exists, or first
        if (!currentFile || !files.includes(currentFile)) {
          currentFile = files.includes('main.pdf') ? 'main.pdf' : files[0];
        }
        select.value = currentFile;
        loadPdf(currentFile);
      } catch (err) {
        console.error('Failed to load file list:', err);
      }
    }

    document.getElementById('file-select').addEventListener('change', (e) => {
      if (e.target.value) {
        currentFile = e.target.value;
        loadPdf(currentFile);
        setupLiveReload();
      }
    });

    document.getElementById('btn-refresh').addEventListener('click', () => {
      if (currentFile) loadPdf(currentFile, true);
    });

    document.getElementById('btn-download').addEventListener('click', () => {
      if (currentFile) {
        window.open('pdf?file=' + encodeURIComponent(currentFile), '_blank');
      }
    });

    function onZoomChange(val) {
      currentScale = val;
      if (currentPdfDoc) renderAllPages(currentPdfDoc, true);
    }

    document.getElementById('btn-zoom-in').addEventListener('click', () => {
      let num = typeof currentScale === 'number' ? currentScale : 1.0;
      currentScale = Math.min(num + 0.25, 3.0);
      document.getElementById('zoom-select').value = String(currentScale);
      if (currentPdfDoc) renderAllPages(currentPdfDoc, true);
    });

    document.getElementById('btn-zoom-out').addEventListener('click', () => {
      let num = typeof currentScale === 'number' ? currentScale : 1.0;
      currentScale = Math.max(num - 0.25, 0.5);
      document.getElementById('zoom-select').value = String(currentScale);
      if (currentPdfDoc) renderAllPages(currentPdfDoc, true);
    });

    async function loadPdf(filename, preserveScroll = false) {
      const container = document.getElementById('viewer-container');
      const scrollTop = container.scrollTop;
      try {
        const loadingTask = pdfjsLib.getDocument('pdf?file=' + encodeURIComponent(filename) + '&t=' + Date.now());
        const pdf = await loadingTask.promise;
        currentPdfDoc = pdf;
        await renderAllPages(pdf, preserveScroll, scrollTop);
      } catch (err) {
        container.innerHTML = '<div id="empty-state">Error loading PDF: ' + err.message + '</div>';
      }
    }

    async function renderAllPages(pdf, preserveScroll = false, savedScrollTop = 0) {
      const container = document.getElementById('viewer-container');
      container.innerHTML = '';

      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        let scale = 1.0;
        const unscaledViewport = page.getViewport({ scale: 1.0 });

        if (currentScale === 'page-width') {
          const availableWidth = Math.min(window.innerWidth - 60, 960);
          scale = availableWidth / unscaledViewport.width;
        } else if (currentScale === 'auto') {
          const availableWidth = Math.min(window.innerWidth - 80, 850);
          scale = availableWidth / unscaledViewport.width;
        } else {
          scale = parseFloat(currentScale) || 1.0;
        }

        const viewport = page.getViewport({ scale: scale });
        const wrapper = document.createElement('div');
        wrapper.className = 'page-wrapper';
        wrapper.dataset.pageNumber = i;

        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        wrapper.appendChild(canvas);
        container.appendChild(wrapper);

        await page.render({ canvasContext: context, viewport: viewport }).promise;
      }

      if (preserveScroll) {
        container.scrollTop = savedScrollTop;
      }
    }

    function setupLiveReload() {
      if (eventSource) {
        eventSource.close();
      }
      eventSource = new EventSource('events?file=' + encodeURIComponent(currentFile));
      eventSource.onmessage = (e) => {
        if (e.data === 'reload') {
          showToast('⚡ PDF auto-reloaded');
          loadPdf(currentFile, true);
        }
      };
      eventSource.onerror = () => {
        // Auto-reconnects by default
      };
    }

    window.addEventListener('resize', () => {
      if (currentScale === 'page-width' || currentScale === 'auto') {
        if (currentPdfDoc) renderAllPages(currentPdfDoc, true, document.getElementById('viewer-container').scrollTop);
      }
    });

    loadFileList();
    setupLiveReload();
  </script>
</body>
</html>
"""

class PDFHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Quiet logging
        pass

    def do_HEAD(self):
        self.do_GET(head_only=True)

    def do_GET(self, head_only=False):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # Normalize path in case of subpaths / proxy
        if path.endswith("/"):
            path = path[:-1]
        if path == "" or path == "/index.html":
            data = INDEX_HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            if not head_only:
                self.wfile.write(data)
            return

        elif "/static/" in path:
            filename = os.path.basename(path)
            filepath = os.path.join(STATIC_DIR, filename)
            if os.path.isfile(filepath):
                with open(filepath, "rb") as f:
                    data = f.read()
                self.send_response(200)
                if filename.endswith(".js"):
                    self.send_header("Content-Type", "application/javascript")
                elif filename.endswith(".css"):
                    self.send_header("Content-Type", "text/css")
                else:
                    self.send_header("Content-Type", "application/octet-stream")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "public, max-age=86400")
                self.end_headers()
                if not head_only:
                    self.wfile.write(data)
            else:
                self.send_error(404, "Static file not found")
            return

        elif path.endswith("/api/files") or path == "/api/files":
            files = []
            if os.path.isdir(WORKSPACE_DIR):
                for root, _, filenames in os.walk(WORKSPACE_DIR):
                    for fn in filenames:
                        if fn.lower().endswith(".pdf"):
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

        elif path.endswith("/pdf") or path == "/pdf":
            rel_file = query.get("file", ["main.pdf"])[0]
            clean_rel = os.path.normpath(rel_file).lstrip("/")
            full_path = os.path.join(WORKSPACE_DIR, clean_rel)
            if not full_path.startswith(os.path.abspath(WORKSPACE_DIR)):
                self.send_error(403, "Access denied")
                return

            if os.path.isfile(full_path):
                try:
                    with open(full_path, "rb") as f:
                        content = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/pdf")
                    self.send_header("Content-Length", str(len(content)))
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.send_header("Cache-Control", "no-cache, must-revalidate")
                    self.end_headers()
                    if not head_only:
                        self.wfile.write(content)
                except Exception as e:
                    self.send_error(500, f"Error reading file: {e}")
            else:
                self.send_error(404, "PDF file not found")
            return

        elif path.endswith("/events") or path == "/events":
            rel_file = query.get("file", ["main.pdf"])[0]
            clean_rel = os.path.normpath(rel_file).lstrip("/")
            full_path = os.path.join(WORKSPACE_DIR, clean_rel)

            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            if head_only:
                return

            last_mtime = os.path.getmtime(full_path) if os.path.isfile(full_path) else 0

            try:
                while True:
                    time.sleep(0.5)
                    current_mtime = os.path.getmtime(full_path) if os.path.isfile(full_path) else 0
                    if current_mtime != last_mtime and current_mtime > 0:
                        last_mtime = current_mtime
                        self.wfile.write(b"data: reload\n\n")
                        self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            return

        else:
            self.send_error(404, "Endpoint not found")

def run():
    server = HTTPServer(("0.0.0.0", PORT), PDFHandler)
    print(f"LaTeX Dark Mode PDF Viewer running at http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    run()
