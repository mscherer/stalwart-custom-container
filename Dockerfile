FROM quay.io/fedora/fedora-minimal:latest
LABEL org.opencontainers.image.source="https://github.com/mscherer/stalwart-custom-container"
LABEL maintainer="mscherer@"
WORKDIR /srv/
RUN dnf install -y git python3-requests --setopt=install_weak_deps=False && dnf clean all
COPY build.py /usr/local/bin/build.py

RUN <<EORUN
# possible features, see the script build.py
# list found with $ grep -r 'cfg(feature' . | sed 's/.*:\s*//'  | sort -u
FEATURES="enterprise"

python3 /usr/local/bin/build.py $FEATURES

ls -lh ./stalwart.bin 
EORUN

FROM scratch
EXPOSE 2507
COPY --from=0 /srv/stalwart/stalwart.bin /srv/stalwart
CMD ["/srv/stalwart"]
