#!/bin/bash
# latex-preview / pdf-view - Manage or view the Live Dark Mode PDF reader status

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
            echo "Started LaTeX Dark Mode PDF Viewer on port ${PORT}."
        else
            echo "LaTeX PDF Viewer is already running."
        fi
        ;;
    stop)
        pkill -f "pdf-server.py" 2>/dev/null && echo "Stopped LaTeX PDF Viewer." || echo "Not running."
        ;;
    restart)
        pkill -f "pdf-server.py" 2>/dev/null
        sleep 1
        touch /var/log/pdf-server.log
        chmod 666 /var/log/pdf-server.log
        nohup python3 /usr/local/bin/pdf-server.py >/var/log/pdf-server.log 2>&1 &
        sleep 1
        echo "Restarted LaTeX Dark Mode PDF Viewer on port ${PORT}."
        ;;
    logs)
        tail -n 50 -f /var/log/pdf-server.log
        exit 0
        ;;
    status|*)
        if ! pgrep -f "pdf-server.py" >/dev/null 2>&1; then
            echo "LaTeX Dark Mode PDF Viewer is NOT running. Starting now..."
            nohup python3 /usr/local/bin/pdf-server.py >/var/log/pdf-server.log 2>&1 &
            sleep 1
        fi
        ;;
esac

echo "=================================================================="
echo "  LaTeX Dark Mode PDF Viewer & Live Auto-Reload"
echo "  - Standalone Host URL:  http://localhost:${PORT}"
echo "  - Via code-server:      http://localhost:8443/proxy/${PORT}/"
echo "  - Workspace Directory:  ${WORKSPACE}"
echo "  - Theme:                Dark Mode (Default) / Light / Sepia"
echo "  - Auto-Reload:          Enabled (Live SSE)"
echo "=================================================================="
