FROM ubuntu:20.04 AS build

ARG ZNC_TAG=znc-1.8.2
ARG PALAVER_TAG=1.2.1
ARG TINI_TAG=v0.19.0
ARG SU_EXEC_TAG=v0.2

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    build-essential \
    libboost-locale1.71-dev \
    libgettextpo-dev \
    gettext \
    git \
    libssl-dev \
    libsasl2-dev \
    cmake \
    libicu-dev \
    ca-certificates \
    zlib1g-dev \
    pkg-config \
  && git clone \
    --branch ${ZNC_TAG} \
    -c advice.detachedHead=false \
    https://github.com/znc/znc /znc-src \
  && git clone \
  -c advice.detachedHead=false \
  https://github.com/jpnurmi/znc-playback \
  /znc-playback \
  && cp /znc-playback/playback.cpp /znc-src/modules/ \
  && git clone \
  -c advice.detachedHead=false \
  https://github.com/Palaver/znc-palaver \
  --branch ${PALAVER_TAG} /znc-palaver \
  && cp /znc-palaver/palaver.cpp /znc-src/modules/ \
  && cd /znc-src \
  && git submodule update --init --recursive \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make \
  && make install \
  && git clone -c advice.detachedHead=false \
  https://github.com/krallin/tini \
  --branch ${TINI_TAG} \
  /tini \
  && cd /tini \
  && cmake . \
  && make tini \
  && git clone \
  -c advice.detachedHead=false \
  https://github.com/ncopa/su-exec \
  --branch ${SU_EXEC_TAG} \
  /su-exec \
  && cd /su-exec \
  && make \
  && mkdir /local_built \
  && cd /local_built \
  && mkdir bin lib share \
  && cp /usr/local/bin/znc bin/ \
  && cp /tini/tini bin/ \
  && cp /su-exec/su-exec bin/ \
  && cp -r /usr/local/lib/znc lib/ \
  && cp -r /usr/local/share/znc share/ \
  && cp -r /usr/local/share/locale share/
  
FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    libssl1.1 \
    libicu66 \
    libsasl2-2 \
    libboost-locale1.71.0 \
    zlib1g \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && useradd -Ms /bin/bash -u 1000 znc \
  && mkdir /znc-data \
  && chown znc /znc-data

COPY --from=build /local_built /usr/local

# not needed if we aren't building modules
#COPY --from=build /usr/local/bin/znc-buildmod /usr/local/bin/
#COPY --from=build /usr/local/lib/pkgconfig/znc.pc /usr/local/lib/pkgconfig/
#COPY --from=build /usr/local/include/znc /usr/local/include/znc

VOLUME /znc-data

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/su-exec", "znc", "/usr/local/bin/znc", "-d", "/znc-data", "-f"]
