FROM quay.io/fedora/fedora-minimal:latest
LABEL org.opencontainers.image.source="https://github.com/mscherer/stalwart-custom-container"
LABEL maintainer="mscherer@"
WORKDIR /srv/
RUN dnf install -y cargo glibc-static git jq curl --setopt=install_weak_deps=False && dnf clean all

RUN <<EORUN
set -e

FEATURES=
PACKAGES=
# possible features:
# storage:
#   sqlite -- sqlite storage
SQLITE=
#   postgres -- postgres storage
POSTGRES=
#   mysql -- mysql storage
MYSQL=
# rocks -- storage on disk
ROCKS=

# s3 -- support any s3 compatible storage 
# redis -- redis support
# azure -- azure blob support
# nats, zenoh, kafka -- used for coordinator 
# foundation, foundationdb -- support for foundationdb (apple nosql db)
# enterprise -- various non free features
#
# list found with $ grep -r 'cfg(feature' . | sed 's/.*:\s*//'  | sort -u

if [ -v SQLITE ]; then
	FEATURES="$FEATURES sqlite"
fi

# I just want the smallest possible binary, so I enable nothing for now
#FEATURES="--no-default-features"
if [ -v FEATURES ]; then
	FEATURES="--features $FEATURES"
fi;
FEATURES="--no-default-features $FEATURES"

REV=$(curl -s "https://api.github.com/repos/stalwartlabs/stalwart/releases/latest" | jq -r .tag_name)
git clone --depth=1 https://github.com/stalwartlabs/stalwart.git --revision=${REV}
cd stalwart 
# see https://msfjarvis.dev/posts/building-static-rust-binaries-for-linux/
# run on 1 single line to not take too much space on my disk with the intermediate container
RUSTFLAGS='-C target-feature=+crt-static' cargo build --release --target $(rustc --print host-tuple) $FEATURES 

mv target/$(rustc --print host-tuple)/release/stalwart ./stalwart.bin 
rm -Rf target
ls -lh ./stalwart.bin 
EORUN

FROM scratch
EXPOSE 2507
COPY --from=0 /srv/stalwart/stalwart.bin /srv/stalwart
CMD ["/srv/stalwart"]
