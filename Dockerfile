FROM debian:bookworm-slim

ARG ORCA_VERSION=1.4.247
ARG GH_VERSION=2.102.0
ARG NODE_VERSION=26.13.0
ARG NODE_SHA256_AMD64=d28a96af6c38596f6d9d97c0ee531c13d238d757742387d1928de822d959e997
ARG NODE_SHA256_ARM64=406fe3fbde1c054adff8b297c16fdb5af6659db327c1ac8acd46b56ef1af9a92
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git openssh-client tini procps less unzip xz-utils build-essential jq \
 && curl -fsSL -o /tmp/orca.deb "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_${TARGETARCH}.deb" \
 && curl -fsSL -o /tmp/gh.deb "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.deb" \
 && apt-get install -y --no-install-recommends /tmp/orca.deb /tmp/gh.deb \
 && rm -rf /tmp/*.deb /var/lib/apt/lists/*

RUN case "$TARGETARCH" in \
      amd64) arch=x64; sum=$NODE_SHA256_AMD64 ;; \
      arm64) arch=arm64; sum=$NODE_SHA256_ARM64 ;; \
      *) echo "no Node build for $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
 && echo "$sum  /tmp/node.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner --exclude CHANGELOG.md --exclude LICENSE --exclude README.md \
 && rm /tmp/node.tar.xz \
 && node --version && npm --version

RUN useradd -m -s /bin/bash dev
USER dev
WORKDIR /home/dev
ENV PATH=/home/dev/.local/bin:$PATH

EXPOSE 6768
ENTRYPOINT ["/usr/bin/tini", "--"]
# --supervise hides the pairing URL when stdout is not a terminal; the container restart policy restarts it instead.
CMD ["sh", "-c", "exec orca-ide serve --port 6768 --pairing-address \"$ORCA_PAIRING_ADDRESS\""]
