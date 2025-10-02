# Multi-stage build for adgenxai-2.0
FROM alpine:latest

# Add metadata
LABEL maintainer="adgenxai-2.0"
LABEL description="AdGenXAI 2.0 - Infrastructure and Automation"

# Install basic utilities
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq

# Copy scripts
WORKDIR /app
COPY scripts/ /app/scripts/
COPY docs/ /app/docs/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Set entrypoint
CMD ["/bin/bash"]
