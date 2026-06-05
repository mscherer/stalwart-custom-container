FROM quay.io/fedora/fedora-minimal@sha256:1e49d1043c41408df854cc0389d5e9f22eff2689490dfe6ddc5cac8cd4fea843



LABEL org.opencontainers.image.source="https://github.com/mscherer/stalwart-custom-container"
LABEL maintainer="mscherer@"
WORKDIR /srv/
RUN dnf install -y git python3-requests --setopt=install_weak_deps=False && dnf clean all
COPY build.py /usr/local/bin/build.py

RUN <<EORUN
# possible features, see the script build.py
# list found with $ grep -r 'cfg(feature' . | sed 's/.*:\s*//'  | sort -u
FEATURES="rocks"

python3 /usr/local/bin/build.py $FEATURES
ls -lh /srv/stalwart
EORUN

FROM scratch
COPY --from=0 /srv/stalwart /srv/stalwart
CMD ["/srv/stalwart"]
