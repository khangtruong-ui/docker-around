#!/bin/bash
# latex-preview / pdf-view - Manage or view the arXiv-Style Paper Reader status

PORT="${PDF_SERVER_PORT:-5000}"
WORKSPACE="${WORKSPACE_DIR:-/home/dev/latex-workspace}"
if [ ! -d "$WORKSPACE" ]; then
    WORKSPACE="${HOME:-/home/dev}"
fi

case "${1:-status}" in
    start)
        if ! pgrep -f "pdf-server.py" >/dev/null 2>&1; then
            touch /var/log/pdf-server.log
            chmod 666 /var/log/pdf-server.log
            nohup python3 /usr/local/bin/pdf-server.py >/var/log/pdf-server.log 2>&1 &
            sleep 1
            echo "Started arXiv-Style Paper Reader on port ${PORT}."
        else
            echo "arXiv-Style Paper Reader is already running."
        fi
        ;;
    stop)
        pkill -f "pdf-server.py" 2>/dev/null && echo "Stopped Paper Reader." || echo "Not running."
        ;;
    restart)
        pkill -f "pdf-server.py" 2>/dev/null
        sleep 1
        touch /var/log/pdf-server.log
        chmod 666 /var/log/pdf-server.log
        nohup python3 /usr/local/bin/pdf-server.py >/var/log/pdf-server.log 2>&1 &
        sleep 1
        echo "Restarted arXiv-Style Paper Reader on port ${PORT}."
        ;;
    logs)
        tail -n 50 -f /var/log/pdf-server.log
        exit 0
        ;;
    status|*)
        if ! pgrep -f "pdf-server.py" >/dev/null 2>&1; then
            echo "arXiv-Style Paper Reader is NOT running. Starting now..."
            nohup python3 /usr/local/bin/pdf-server.py >/var/log/pdf-server.log 2>&1 &
            sleep 1
        fi
        ;;
esac

echo "=================================================================="
echo "  arXiv-Style Paper Reader & Live Auto-Reload Server"
echo "  - Direct Host URL:      http://localhost:${PORT}"
echo "  - Via code-server:      http://localhost:8443/proxy/${PORT}/"
echo "  - Direct HTML Paper:    http://localhost:${PORT}/html?file=main.html"
echo "  - Direct Native PDF:    http://localhost:${PORT}/pdf?file=main.pdf"
echo "  - Workspace:            ${WORKSPACE}"
echo "  - Features:             arXiv HTML (<10ms), Native PDF (C++),"
echo "                          Dark Mode, MathJax, Live Auto-Reload"
echo "=================================================================="
