# syntax=docker/dockerfile:1

#################################################################################################################
## This Dockerfile contains all the necessary tools to work with the project's Infrastructure locally. By      ##
## using it, you don't need to install anything on your host system, as everything is already included in this ##
## Docker image.                                                                                               ##
#################################################################################################################

FROM docker.io/library/alpine:3.21

# install dnscontrol (https://github.com/StackExchange/dnscontrol)
COPY --from=ghcr.io/stackexchange/dnscontrol:4.15.6 /usr/local/bin/dnscontrol /usr/local/bin/dnscontrol

# install doppler (https://github.com/DopplerHQ/cli)
RUN set -x \
    # renovate: source=github-releases name=DopplerHQ/cli
    && DOPPLER_VERSION="3.74.0" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) DOPPLER_ARCH="amd64" ;; \
        aarch64) DOPPLER_ARCH="arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://github.com/DopplerHQ/cli/releases/download" \
    && wget -q "${BASE_URL}/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION}_linux_${DOPPLER_ARCH}.tar.gz" -O - | \
      tar -xzO "doppler" > /usr/local/bin/doppler \
    && chmod +x /usr/local/bin/doppler \
    && doppler --version

# install terraform (https://www.terraform.io/)
RUN set -x \
    # renovate: source=github-releases name=hashicorp/terraform
    && TERRAFORM_VERSION="1.11.2" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) TERRAFORM_ARCH="amd64" ;; \
        aarch64) TERRAFORM_ARCH="arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://releases.hashicorp.com/terraform" \
    && wget -q -O /tmp/terraform.zip \
      "${BASE_URL}/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && rm -f /tmp/terraform.zip \
    && chmod +x /usr/local/bin/terraform \
    && terraform version
