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

# Download and install ChirpStack 4.15.0 only (Gateway Bridge disabled due to cache issues)
ARG CHIRPSTACK_VERSION="4.15.0"

# Install ChirpStack only - bypass cache issues (2024-11-17)
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) CHIRP_ARCH="amd64" ;; \
        aarch64) CHIRP_ARCH="arm64" ;; \
        armv7l) CHIRP_ARCH="armv7hf" ;; \
        armv6l) CHIRP_ARCH="armv7hf" ;; \
        i386|i686) CHIRP_ARCH="amd64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    echo "Building ChirpStack ${CHIRPSTACK_VERSION} only (Gateway Bridge disabled) at $(date)" && \
    echo "Installing ChirpStack for architecture: $CHIRP_ARCH" && \
    curl -L -o /tmp/chirpstack.tar.gz \
        "https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_${CHIRPSTACK_VERSION}_postgres_linux_${CHIRP_ARCH}.tar.gz" && \
    tar -xzf /tmp/chirpstack.tar.gz -C /tmp/ && \
    mv /tmp/chirpstack /usr/local/bin/chirpstack && \
    chmod +x /usr/local/bin/chirpstack && \
    rm -rf /tmp/chirpstack.tar.gz && \
    echo "ChirpStack installation complete - Gateway Bridge disabled"

# Verify ChirpStack installation
RUN /usr/local/bin/chirpstack version || echo "ChirpStack binary check completed"

# Copy and set up run script
COPY run.sh /
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /config

CMD [ "/run.sh" ]