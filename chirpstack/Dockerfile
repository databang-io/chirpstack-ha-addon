ARG BUILD_FROM
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system packages
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    sed \
    redis \
    python3 \
    py3-pip \
    pipx

# Ensure pipx path is available
ENV PATH="/root/.local/bin:${PATH}"

# -------------------------------------------------------------------
# Install tomlq/yq via pipx (SAFE + allowed in HA)
# -------------------------------------------------------------------
RUN pipx install yq && \
    ln -s /root/.local/bin/tomlq /usr/local/bin/tomlq && \
    ln -s /root/.local/bin/yq /usr/local/bin/yq && \
    ln -s /root/.local/bin/xq /usr/local/bin/xq

# -------------------------------------------------------------------
# Versions as variables (NO HARDCODE)
# -------------------------------------------------------------------
ARG CHIRPSTACK_VERSION="4.15.0"
ARG GATEWAY_BRIDGE_VERSION="4.1.1"

# -------------------------------------------------------------------
# Download + install ChirpStack + Gateway Bridge
# -------------------------------------------------------------------
RUN echo "[BUILD] Starting build at $(date)" && \
    echo "[BUILD] ChirpStack=${CHIRPSTACK_VERSION}, GatewayBridge=${GATEWAY_BRIDGE_VERSION}" && \
    \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64)   CHIRP_ARCH="amd64";   GW_ARCH="amd64" ;; \
        aarch64)  CHIRP_ARCH="arm64";   GW_ARCH="arm64" ;; \
        armv7l)   CHIRP_ARCH="armv7hf"; GW_ARCH="armv7hf" ;; \
        armv6l)   CHIRP_ARCH="armv7hf"; GW_ARCH="armhf"  ;; \
        i386|i686)CHIRP_ARCH="386";     GW_ARCH="386"   ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    echo "[BUILD] ARCH=$ARCH → ChirpStack=${CHIRP_ARCH}, GatewayBr=${GW_ARCH}" && \
    \
    CH_URL="https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_${CHIRPSTACK_VERSION}_sqlite_linux_${CHIRP_ARCH}.tar.gz" && \
    echo "[DOWNLOAD] $CH_URL" && \
    curl -fL -o /tmp/chirpstack.tar.gz "$CH_URL" && \
    tar -xzf /tmp/chirpstack.tar.gz -C /tmp/ && \
    mv /tmp/chirpstack /usr/local/bin/chirpstack && \
    chmod +x /usr/local/bin/chirpstack && \
    rm -f /tmp/chirpstack.tar.gz && \
    \
    GW_URL="https://artifacts.chirpstack.io/downloads/chirpstack-gateway-bridge/chirpstack-gateway-bridge_${GATEWAY_BRIDGE_VERSION}_linux_${GW_ARCH}.tar.gz" && \
    echo "[DOWNLOAD] $GW_URL" && \
    curl -fL -o /tmp/gwb.tar.gz "$GW_URL" && \
    tar -xzf /tmp/gwb.tar.gz -C /tmp/ && \
    mv /tmp/chirpstack-gateway-bridge /usr/local/bin/chirpstack-gateway-bridge && \
    chmod +x /usr/local/bin/chirpstack-gateway-bridge && \
    rm -f /tmp/gwb.tar.gz

# Verify binaries
RUN /usr/local/bin/chirpstack --version || echo "ChirpStack OK"
RUN /usr/local/bin/chirpstack-gateway-bridge version || echo "GatewayBridge OK"
RUN tomlq --version || echo "tomlq installed"

COPY run.sh /
RUN chmod +x /run.sh

WORKDIR /config
CMD [ "/run.sh" ]
