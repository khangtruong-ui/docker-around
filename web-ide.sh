#!/bin/bash
# web-ide / latex-editor - Start or view code-server Web LaTeX IDE status

PORT="8443"
WORKSPACE="${WORKSPACE_DIR:-/home/dev/latex-workspace}"
if [ ! -d "$WORKSPACE" ]; then
    WORKSPACE="${HOME:-/home/dev}"
fi

ACTION="${1:-status}"
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    PORT="$ACTION"
    ACTION="start"
fi

case "$ACTION" in
    stop)
        pkill -f "/usr/lib/code-server" 2>/dev/null && echo "Stopped code-server." || echo "code-server is not running."
        exit 0
        ;;
    restart)
        pkill -f "/usr/lib/code-server" 2>/dev/null
        sleep 1
        ;;
    logs)
        tail -n 50 -f /var/log/code-server.log
        exit 0
        ;;
    status)
        ;;
    start|*)
        ;;
esac

if ! pgrep -f "/usr/lib/code-server" >/dev/null 2>&1; then
    echo "Starting code-server Web LaTeX IDE on port ${PORT}..."
    touch /var/log/code-server.log
    chmod 666 /var/log/code-server.log
    if id dev >/dev/null 2>&1; then
        chown dev:dev /var/log/code-server.log 2>/dev/null || true
        nohup su - dev -c "code-server --bind-addr 0.0.0.0:${PORT} '${WORKSPACE}'" >/var/log/code-server.log 2>&1 &
    else
        nohup code-server --bind-addr 0.0.0.0:${PORT} "${WORKSPACE}" >/var/log/code-server.log 2>&1 &
    fi
    sleep 1
fi

echo "=================================================================="
echo "  Web LaTeX IDE (code-server) is running on port ${PORT}"
echo "  Access in Host Browser: http://localhost:${PORT}"
echo "  Workspace: ${WORKSPACE}"
echo "  Default Password: dev (or configured via PASSWORD env var)"
echo "=================================================================="
