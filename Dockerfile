FROM quay.io/fedora/fedora-minimal@sha256:587b23d1062e8234ddcebaf50ad1fd71175da89274b3b5461f9cff81cda3f625



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
# https / http
EXPOSE 443 8080
# smtp / smtps / submission
EXPOSE 25 465 587
# pop3 / pop3s
EXPOSE 110 995
# imap / imaps
EXPOSE 143 993
# sieve
EXPOSE 4190
VOLUME ["/etc/stalwart", "/var/lib/stalwart", "/etc/pki", "/etc/ssl"]
COPY --from=0 /srv/stalwart /srv/stalwart
ENTRYPOINT ["/srv/stalwart"]
CMD ["--config", "/etc/stalwart/config.json"]
