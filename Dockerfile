FROM postgres:alpine as builder

ENV PLV8_BRANCH=r3.2
ENV PLV8_VERSION=3.2.4
ENV PG_MAJOR=18

ARG BIGINT_GRACEFUL_VALUE='BIGINT_GRACEFUL=1'
ARG BIGINT_GRACEFUL
ARG BIGINT_GRACEFUL_FLAG=${BIGINT_GRACEFUL:+$BIGINT_GRACEFUL_VALUE}

RUN apk update \
    && apk add --no-cache --virtual .v8-build \
  libstdc++-dev \
  binutils \
  gcc \
  libc-dev \
  g++ \
  patch \  
  ca-certificates \
  curl \
  make \
  libbz2 \
  linux-headers \
  cmake \
  clang19-libs \
  clang19 \
  llvm19 \
  ncurses-libs \
  zlib-dev \
  git \
  python3


RUN mkdir -p /tmp/build \
  && cd /tmp/build \
  && git clone --branch ${PLV8_BRANCH} --depth 1 https://github.com/plv8/plv8.git \
  && cd plv8 \
  && git submodule update --init \
  && cd deps/v8-cmake \
  && git checkout master


RUN  cd /tmp/build/plv8 \
  && export GYP_DEFINES="linux_use_bundled_binutils=0" \
  && make ${BIGINT_GRACEFUL_FLAG} \
  && strip plv8-${PLV8_VERSION}.so \
  && make install

RUN apk del --no-network .v8-build; \
  rm -rf /tmp/* /var/tmp/*


FROM postgres:alpine
ENV PLV8_VERSION=3.2.4
COPY --from=builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/plv8-${PLV8_VERSION}.so /usr/local/lib/postgresql/plv8-${PLV8_VERSION}.so
