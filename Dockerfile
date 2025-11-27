FROM bitnami/minideb:trixie@sha256:cc9c926a9613976b1ab098f3d2eb131d1e218bdcd38ac558fbe4a74f17a94893
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment
RUN apt update && apt install -y checkinstall libusb-1.0-0-dev git \
    libgd-dev cmake make gcc gettext printer-driver-ptouch sudo
RUN addgroup --gid $GID nonroot && \
    adduser --uid $UID --gid $GID --disabled-password --gecos "" nonroot && \
    echo 'nonroot ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN mkdir -p /etc/udev/rules.d

VOLUME ["/app"]
WORKDIR /app

USER nonroot
