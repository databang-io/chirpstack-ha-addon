ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install requirements for ChirpStack and Home Assistant integration
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    sed

# Download and install ChirpStack 4.15.0 and Gateway Bridge 4.1.1 (FRESH REPO)
ARG CHIRPSTACK_VERSION="4.15.0"
ARG GATEWAY_BRIDGE_VERSION="4.1.1"

# FORCE CACHE BREAK - Gateway Bridge 4.1.1 ONLY (NOT 4.0.12)
RUN echo "CACHE BREAK $(date +%s): Gateway Bridge 4.1.1" && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) CHIRP_ARCH="amd64"; GW_ARCH="amd64" ;; \
        aarch64) CHIRP_ARCH="arm64"; GW_ARCH="arm64" ;; \
        armv7l) CHIRP_ARCH="armv7hf"; GW_ARCH="armv7hf" ;; \
        armv6l) CHIRP_ARCH="armv7hf"; GW_ARCH="armhf" ;; \
        i386|i686) CHIRP_ARCH="amd64"; GW_ARCH="386" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    echo "BUILDING: ChirpStack ${CHIRPSTACK_VERSION} and Gateway Bridge ${GATEWAY_BRIDGE_VERSION} at $(date)" && \
    echo "VERIFY VERSION: Gateway Bridge should be 4.1.1, ARG shows: ${GATEWAY_BRIDGE_VERSION}" && \
    echo "Installing ChirpStack for architecture: $CHIRP_ARCH" && \
    curl -L -o /tmp/chirpstack.tar.gz \
        "https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_${CHIRPSTACK_VERSION}_sqlite_linux_${CHIRP_ARCH}.tar.gz" && \
    tar -xzf /tmp/chirpstack.tar.gz -C /tmp/ && \
    mv /tmp/chirpstack /usr/local/bin/chirpstack && \
    chmod +x /usr/local/bin/chirpstack && \
    rm -rf /tmp/chirpstack.tar.gz && \
    echo "Installing Gateway Bridge for architecture: $GW_ARCH" && \
    echo "Gateway Bridge URL: https://artifacts.chirpstack.io/downloads/chirpstack-gateway-bridge/chirpstack-gateway-bridge_${GATEWAY_BRIDGE_VERSION}_linux_${GW_ARCH}.tar.gz" && \
    curl -L -o /tmp/chirpstack-gateway-bridge.tar.gz \
        "https://artifacts.chirpstack.io/downloads/chirpstack-gateway-bridge/chirpstack-gateway-bridge_${GATEWAY_BRIDGE_VERSION}_linux_${GW_ARCH}.tar.gz" && \
    tar -xzf /tmp/chirpstack-gateway-bridge.tar.gz -C /tmp/ && \
    mv /tmp/chirpstack-gateway-bridge /usr/local/bin/chirpstack-gateway-bridge && \
    chmod +x /usr/local/bin/chirpstack-gateway-bridge && \
    rm -rf /tmp/chirpstack-gateway-bridge.tar.gz

# Verify installations
RUN /usr/local/bin/chirpstack version || echo "ChirpStack binary check completed"
RUN /usr/local/bin/chirpstack-gateway-bridge version || echo "Gateway Bridge binary check completed"

# Copy and set up run script
COPY run.sh /
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /config

CMD [ "/run.sh" ]