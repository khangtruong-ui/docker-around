#!/bin/bash
set -e

export HOME="${HOME:-/root}"
export USER="${USER:-root}"
export TERM="${TERM:-xterm-256color}"
export PATH="/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Generate SSH host keys if not present and ensure run directories exist
mkdir -p /run/sshd /var/run/sshd /var/run/dbus /var/log
rm -f /run/nologin /var/run/nologin
ssh-keygen -A 2>/dev/null || true

# Start dbus service for XFCE desktop environment
service dbus start >/dev/null 2>&1 || /etc/init.d/dbus start >/dev/null 2>&1 || true

# Add fallback DNS if needed for reliable container network resolution
if ! grep -q "8.8.8.8" /etc/resolv.conf 2>/dev/null; then
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
fi

# Start or verify Docker daemon in background (non-blocking)
if [ "$(id -u)" -eq 0 ] && [ -x /etc/init.d/docker ]; then
    /etc/init.d/docker start >/dev/null 2>&1 &
fi

# Start Web Terminal (ttyd on port 7681) in background if available
if [ -x /usr/local/bin/ttyd ] && ! pgrep -x ttyd >/dev/null 2>&1; then
    nohup /usr/local/bin/ttyd -W -p 7681 /bin/bash >/var/log/ttyd.log 2>&1 &
fi

# Start Web IPython / JupyterLab (on port 8888) in background if available
if [ -x /opt/venv/bin/jupyter ] && ! pgrep -f "jupyter" >/dev/null 2>&1; then
    nohup /opt/venv/bin/jupyter lab \
        --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --ServerApp.token='' --ServerApp.password='' \
        --NotebookApp.token='' --NotebookApp.password='' \
        >/var/log/jupyter.log 2>&1 &
fi

# Start code-server (Web LaTeX / VS Code IDE on port 8443) in background if available
if command -v code-server >/dev/null 2>&1 && ! pgrep -f "/usr/lib/code-server" >/dev/null 2>&1; then
    CS_AUTH="none"
    CODE_PWD="${CODE_SERVER_PASSWORD:-${PASSWORD:-dev}}"
    if [ "${CODE_SERVER_AUTH:-}" = "none" ] || [ "${PASSWORD:-unset}" = "" ]; then
        CS_AUTH="none"
    elif [ -n "$CODE_PWD" ]; then
        CS_AUTH="password"
    fi

    # Ensure log file exists and is accessible
    touch /var/log/code-server.log
    chmod 666 /var/log/code-server.log

    if id dev >/dev/null 2>&1; then
        mkdir -p /home/dev/.config/code-server \
                 /home/dev/.local/share/code-server/User \
                 /home/dev/.local/share/code-server/extensions \
                 /home/dev/latex-workspace/.vscode

        # Write config.yaml
        cat <<EOF > /home/dev/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8443
auth: ${CS_AUTH}
password: ${CODE_PWD}
cert: false
EOF

        # Restore settings/extensions if a volume was mounted over /home/dev
        if [ ! -f /home/dev/.local/share/code-server/User/settings.json ] && [ -f /etc/skel/.local/share/code-server/User/settings.json ]; then
            cp /etc/skel/.local/share/code-server/User/settings.json /home/dev/.local/share/code-server/User/settings.json
        fi
        if [ -f /etc/skel/.local/share/code-server/User/settings.json ] && [ ! -f /home/dev/latex-workspace/.vscode/settings.json ]; then
            cp /etc/skel/.local/share/code-server/User/settings.json /home/dev/latex-workspace/.vscode/settings.json
        fi
        if [ ! -d /home/dev/.local/share/code-server/extensions/james-yu.latex-workshop* ] && [ -d /root/.local/share/code-server/extensions/james-yu.latex-workshop* ]; then
            cp -r /root/.local/share/code-server/extensions/james-yu.latex-workshop* /home/dev/.local/share/code-server/extensions/ 2>/dev/null || true
        fi
        if [ ! -d /home/dev/.agents/skills/latex ] && [ -d /usr/local/share/agy-skills/latex ]; then
            cp -r /usr/local/share/agy-skills/latex /home/dev/.agents/skills/ 2>/dev/null || true
            cp -r /usr/local/share/agy-skills/latex /home/dev/.gemini/config/skills/ 2>/dev/null || true
        fi
        if [ ! -f /home/dev/latex-workspace/main.tex ] && [ -x /usr/local/bin/latex-template ]; then
            /usr/local/bin/latex-template paper /home/dev/latex-workspace 2>/dev/null || true
        fi

        # Fast non-recursive chown for new files
        chown dev:dev /home/dev/.config/code-server/config.yaml /var/log/code-server.log 2>/dev/null || true
        chown dev:dev /home/dev/.config/code-server /home/dev/latex-workspace 2>/dev/null || true

        # Launch code-server as dev user opening the latex workspace
        nohup su - dev -c "code-server --bind-addr 0.0.0.0:8443 /home/dev/latex-workspace" >/var/log/code-server.log 2>&1 &
    else
        mkdir -p /root/.config/code-server /root/latex-workspace/.vscode
        cat <<EOF > /root/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8443
auth: ${CS_AUTH}
password: ${CODE_PWD}
cert: false
EOF
        if [ -f /tmp/settings.json ] && [ ! -f /root/latex-workspace/.vscode/settings.json ]; then
            cp /tmp/settings.json /root/latex-workspace/.vscode/settings.json 2>/dev/null || true
        fi
        nohup code-server --bind-addr 0.0.0.0:8443 /root/latex-workspace >/var/log/code-server.log 2>&1 &
    fi
fi

# Ensure user dev session configuration exists
mkdir -p /home/dev/.config/chrome-remote-desktop
chown -R dev:dev /home/dev/.config
chown dev:dev /home/dev/.chrome-remote-desktop-session 2>/dev/null || true

# Auto-start Chrome Remote Desktop
if ls /home/dev/.config/chrome-remote-desktop/host#*.json 1>/dev/null 2>&1; then
    # Already configured from volume or previous run: start daemon
    if ! pgrep -f "chrome-remote-desktop.*child-process" >/dev/null 2>&1; then
        echo "Resuming Chrome Remote Desktop session for user dev..."
        su - dev -c "nohup /opt/google/chrome-remote-desktop/chrome-remote-desktop --start --child-process >/var/log/crd.log 2>&1 &"
    fi
elif [ -n "$CRD_CODE" ]; then
    # Automatic registration via environment variable
    PIN="${CRD_PIN:-123456}"
    HOST_NAME="${CRD_NAME:-$(hostname)}"
    echo "Registering Chrome Remote Desktop with provided auth code as host '$HOST_NAME'..."
    printf "%s\n%s\n" "$PIN" "$PIN" | su - dev -c "DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=\"$CRD_CODE\" --redirect-url=\"https://remotedesktop.google.com/_/oauthredirect\" --name=\"$HOST_NAME\"" >/var/log/crd-setup.log 2>&1 || true
    sleep 2
    if ! pgrep -f "chrome-remote-desktop.*child-process" >/dev/null 2>&1; then
        su - dev -c "nohup /opt/google/chrome-remote-desktop/chrome-remote-desktop --start --child-process >/var/log/crd.log 2>&1 &" || true
    fi
    if pgrep -f "chrome-remote-desktop.*child-process" >/dev/null 2>&1; then
        echo "Chrome Remote Desktop is active and online!"
    fi
fi

# Check if default shell was requested
is_default=false
if [ $# -eq 0 ]; then
    is_default=true
elif [ $# -eq 1 ] && { [ "$1" = "/bin/bash" ] || [ "$1" = "bash" ] || [ "$1" = "/bin/sh" ] || [ "$1" = "sh" ]; }; then
    is_default=true
fi

if [ "$is_default" = true ]; then
    if [ -t 0 ]; then
        /usr/sbin/sshd 2>/dev/null || true
        exec /bin/bash
    else
        exec /usr/sbin/sshd -D -e
    fi
else
    case "$1" in
        *sshd*)
            ;;
        *)
            /usr/sbin/sshd 2>/dev/null || true
            ;;
    esac
    exec "$@"
fi
