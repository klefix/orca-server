FROM debian:bookworm-slim

ARG ORCA_VERSION=1.4.247
ARG GH_VERSION=2.102.0
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git openssh-client tini procps less \
 && curl -fsSL -o /tmp/orca.deb "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_${TARGETARCH}.deb" \
 && curl -fsSL -o /tmp/gh.deb "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.deb" \
 && apt-get install -y --no-install-recommends /tmp/orca.deb /tmp/gh.deb \
 && rm -rf /tmp/*.deb /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dev
USER dev
WORKDIR /home/dev
ENV PATH=/home/dev/.local/bin:$PATH

EXPOSE 6768
ENTRYPOINT ["/usr/bin/tini", "--"]
# --supervise hides the pairing URL when stdout is not a terminal; the container restart policy restarts it instead.
CMD ["sh", "-c", "exec orca-ide serve --port 6768 --pairing-address \"$ORCA_PAIRING_ADDRESS\""]
