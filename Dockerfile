FROM quay.io/fedora/fedora-minimal@sha256:e2b0254d630ad779d8f4c6c6b849c3b12540df18698ad2d7196f64dc83293f78



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
