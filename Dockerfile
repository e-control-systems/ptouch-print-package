FROM bitnami/minideb:trixie@sha256:cc9c926a9613976b1ab098f3d2eb131d1e218bdcd38ac558fbe4a74f17a94893

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment
RUN apt update && apt install -y checkinstall libusb-1.0-0-dev libgd-dev git cmake make gcc gettext printer-driver-ptouch
RUN mkdir -p /etc/udev/rules.d
