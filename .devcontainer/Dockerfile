FROM ghcr.io/home-assistant/devcontainer:addons

# Install additional tools for development
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*