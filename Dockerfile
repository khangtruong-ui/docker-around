FROM khangtruong1108/basic:chrome-remote

LABEL maintainer="khangtruong1108"
LABEL description="Developer container with TeX Live, code-server, TeXstudio, AGY LaTeX skill, SSH, and Chrome Remote Desktop"

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install LaTeX Compiler Suite, Utilities, Pandoc, MathJax & GUI Tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-science \
    texlive-xetex \
    texlive-luatex \
    texlive-bibtex-extra \
    texlive-publishers \
    biber \
    latexmk \
    chktex \
    pandoc \
    libjs-mathjax \
    python3-pygments \
    ghostscript \
    qpdf \
    poppler-utils \
    texstudio \
    evince \
    libyaml-tiny-perl \
    libfile-homedir-perl \
    libunicode-linebreak-perl \
    curl \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Install code-server (Web VS Code IDE)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 3. Pre-install LaTeX Workshop & Dark Mode PDF Extensions for code-server
RUN code-server --install-extension James-Yu.latex-workshop \
    && code-server --install-extension els4nta.vscode-magic-pdf \
    && code-server --install-extension tomoki1207.pdf \
    && code-server --install-extension adamraichu.pdf-viewer \
    && find /root/.local/share/code-server/extensions -name "viewer.js" -path "*/james-yu.latex-workshop*/out/src/preview/viewer.js" -exec sed -i "s/\x27latex-workshop-pdf-hook\x27/\x27magicPdf.preview\x27/g" {} + \
    && find /root/.local/share/code-server/extensions -name "package.json" -path "*/james-yu.latex-workshop*/package.json" -exec sed -i 's/"priority": "default"/"priority": "option"/g' {} + \
    && mkdir -p /usr/local/share/pdf-viewer \
    && cp /root/.local/share/code-server/extensions/adamraichu.pdf-viewer*/media/pdf.min.js /usr/local/share/pdf-viewer/ \
    && cp /root/.local/share/code-server/extensions/adamraichu.pdf-viewer*/media/pdf.worker.min.js /usr/local/share/pdf-viewer/

# 4. Configure code-server settings for both dev and root
COPY vscode-settings.json /tmp/settings.json

RUN mkdir -p /root/.local/share/code-server/User \
             /root/.local/share/code-server/extensions \
             /home/dev/.local/share/code-server/User \
             /home/dev/.local/share/code-server/extensions \
             /etc/skel/.local/share/code-server/User \
             /etc/skel/.local/share/code-server/extensions \
    && cp /tmp/settings.json /root/.local/share/code-server/User/settings.json \
    && cp /tmp/settings.json /home/dev/.local/share/code-server/User/settings.json \
    && cp /tmp/settings.json /etc/skel/.local/share/code-server/User/settings.json \
    && cp -r /root/.local/share/code-server/extensions/* /home/dev/.local/share/code-server/extensions/ 2>/dev/null || true \
    && cp -r /root/.local/share/code-server/extensions/* /etc/skel/.local/share/code-server/extensions/ 2>/dev/null || true \
    && chown -R dev:dev /home/dev/.local /home/dev/.config 2>/dev/null || true

# 5. Install AGY LaTeX Skill, arXiv HTML theme & system helper scripts
COPY skills/latex /usr/local/share/agy-skills/latex
COPY web-ide.sh /usr/local/bin/web-ide
COPY pdf-server.py /usr/local/bin/pdf-server.py
COPY latex-preview.sh /usr/local/bin/latex-preview
COPY arxiv-theme.css /usr/local/share/latex-html/arxiv-theme.css

RUN chmod +x /usr/local/share/agy-skills/latex/scripts/*.sh \
    && chmod +x /usr/local/bin/web-ide /usr/local/bin/pdf-server.py /usr/local/bin/latex-preview \
    && ln -sf /usr/local/bin/web-ide /usr/local/bin/latex-editor \
    && ln -sf /usr/local/bin/latex-preview /usr/local/bin/pdf-view \
    && ln -sf /usr/local/bin/latex-preview /usr/local/bin/pdf-viewer \
    && ln -sf /usr/local/share/agy-skills/latex/scripts/compile.sh /usr/local/bin/latex-compile \
    && ln -sf /usr/local/share/agy-skills/latex/scripts/to-html.sh /usr/local/bin/latex-to-html \
    && ln -sf /usr/local/share/agy-skills/latex/scripts/clean.sh /usr/local/bin/latex-clean \
    && ln -sf /usr/local/share/agy-skills/latex/scripts/lint.sh /usr/local/bin/latex-lint \
    && ln -sf /usr/local/share/agy-skills/latex/scripts/template.sh /usr/local/bin/latex-template \
    && mkdir -p /root/.gemini/config/skills \
                /home/dev/.gemini/config/skills \
                /etc/skel/.gemini/config/skills \
                /root/.agents/skills \
                /home/dev/.agents/skills \
    && cp -r /usr/local/share/agy-skills/latex /root/.gemini/config/skills/ \
    && cp -r /usr/local/share/agy-skills/latex /home/dev/.gemini/config/skills/ \
    && cp -r /usr/local/share/agy-skills/latex /etc/skel/.gemini/config/skills/ \
    && cp -r /usr/local/share/agy-skills/latex /root/.agents/skills/ \
    && cp -r /usr/local/share/agy-skills/latex /home/dev/.agents/skills/ \
    && touch /var/log/code-server.log /var/log/pdf-server.log \
    && chmod 666 /var/log/code-server.log /var/log/pdf-server.log \
    && chown -R dev:dev /home/dev/.gemini /home/dev/.agents 2>/dev/null || true

# 6. Configure Desktop Shortcuts for TeXstudio and Evince in Chrome Remote Desktop
RUN mkdir -p /home/dev/Desktop /root/Desktop /etc/skel/Desktop \
    && cp /usr/share/applications/texstudio.desktop /home/dev/Desktop/ 2>/dev/null || true \
    && cp /usr/share/applications/org.gnome.Evince.desktop /home/dev/Desktop/ 2>/dev/null || true \
    && cp /usr/share/applications/texstudio.desktop /root/Desktop/ 2>/dev/null || true \
    && cp /usr/share/applications/org.gnome.Evince.desktop /root/Desktop/ 2>/dev/null || true \
    && chmod +x /home/dev/Desktop/*.desktop /root/Desktop/*.desktop /etc/skel/Desktop/*.desktop 2>/dev/null || true \
    && chown -R dev:dev /home/dev/Desktop 2>/dev/null || true

# 7. Create starter LaTeX workspace & pre-generate arXiv-style HTML paper
RUN mkdir -p /home/dev/latex-workspace/.vscode /root/latex-workspace/.vscode \
    && /usr/local/bin/latex-template paper /home/dev/latex-workspace \
    && /usr/local/bin/latex-to-html /home/dev/latex-workspace/main.tex /home/dev/latex-workspace/main.html \
    && cp -r /home/dev/latex-workspace/* /root/latex-workspace/ \
    && cp /tmp/settings.json /home/dev/latex-workspace/.vscode/settings.json \
    && cp /tmp/settings.json /root/latex-workspace/.vscode/settings.json \
    && chown -R dev:dev /home/dev/latex-workspace 2>/dev/null || true

# 8. Copy comprehensive documentation
COPY README.md /root/README.md
COPY README.md /home/dev/README.md
RUN chown dev:dev /home/dev/README.md 2>/dev/null || true

# 9. Copy Entrypoint & Expose ports
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22 5000 6419 7681 8443 8888

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
