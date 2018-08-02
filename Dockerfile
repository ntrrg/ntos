FROM debian:buster AS rootfs
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -qy debootstrap
COPY scripts/rootfs.sh /
RUN ./rootfs.sh
