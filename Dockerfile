ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG BASE_USER=root
ARG CEPH_RELEASE=tentacle
ARG DISTRO_CODENAME=noble
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends gnupg ca-certificates curl \
 && curl -fsSL https://download.ceph.com/keys/release.asc | gpg --dearmor -o /usr/share/keyrings/ceph-release.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/ceph-release.gpg] https://download.ceph.com/debian-${CEPH_RELEASE}/ ${DISTRO_CODENAME} main" > /etc/apt/sources.list.d/ceph-release.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends ceph-common librados2 librbd1 python3-rados python3-rbd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
USER ${BASE_USER}
