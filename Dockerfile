# Moli on Railway: the official Moli v1.1.22 Linux x86_64 release binary
# (lexmount/moli, Apache-2.0 OR MIT) behind nginx in ONE container.
#   - `moli serve` binds 127.0.0.1 only; upstream says never expose raw CDP.
#   - nginx on Railway's $PORT only forwards /t/<MOLI_TOKEN>/..., so the
#     automation endpoint is a secret URL (works with any CDP/WebDriver client
#     without custom headers). It rewrites ws://127.0.0.1:9223 in discovery
#     JSON to wss://<your-domain>/t/<token>, sets Host to a loopback literal
#     (Moli rejects non-IP Host headers) and drops Origin.
FROM debian:bookworm-slim
ARG MOLI_VERSION=1.1.22
ARG MOLI_SHA256=7e10f9a5b62371da56203b21ac0172bbe3c3626de189fc3742b91b2e2b8cdd39
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini nginx gettext-base \
      libfontconfig1 libfreetype6 libpng16-16 libbrotli1 libexpat1 zlib1g libbz2-1.0 libstdc++6 \
      fonts-dejavu-core fonts-liberation2 fonts-noto-core fonts-noto-cjk \
 && curl -fsSL -o /tmp/moli.tgz "https://github.com/lexmount/moli/releases/download/v${MOLI_VERSION}/moli-x86_64-unknown-linux-gnu.tar.gz" \
 && echo "${MOLI_SHA256}  /tmp/moli.tgz" | sha256sum -c - \
 && tar xzf /tmp/moli.tgz -C /tmp \
 && install -m 755 /tmp/moli-v${MOLI_VERSION}-x86_64-unknown-linux-gnu/moli /usr/local/bin/moli \
 && mkdir -p /usr/share/licenses/moli && cp -r /tmp/moli-v${MOLI_VERSION}-x86_64-unknown-linux-gnu/LICENSE* /tmp/moli-v${MOLI_VERSION}-x86_64-unknown-linux-gnu/licenses /usr/share/licenses/moli/ \
 && rm -rf /tmp/moli* /var/lib/apt/lists/* /etc/nginx/sites-enabled/default \
 && useradd -m -u 10001 moli \
 && moli --version
COPY railway/nginx.conf.template /etc/moli-railway/nginx.conf.template
COPY railway/start.sh /usr/local/bin/moli-railway-start
RUN chmod 755 /usr/local/bin/moli-railway-start
# Plain defaults live in the image; the template only carries the generated
# MOLI_TOKEN. MOLI_SERVE_ARGS are extra flags for `moli serve`.
ENV PORT=8080 \
    MOLI_INTERNAL_PORT=9223 \
    MOLI_SERVE_ARGS="--layout"
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -sf "http://127.0.0.1:${PORT:-8080}/healthz" || exit 1
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/moli-railway-start"]
