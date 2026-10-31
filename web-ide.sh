#!/bin/bash
# web-ide / latex-editor - Start or view code-server Web LaTeX IDE status

PORT="${1:-8443}"
WORKSPACE="${2:-/home/dev/latex-workspace}"
if [ ! -d "$WORKSPACE" ]; then
    WORKSPACE="${HOME:-/home/dev}"
fi

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
