# Docker build arguments
ARG DOTNET_VERSION=8.0
ARG NODEJS_VERSION=20

# Combined image version (Debian)
ARG OS_VERSION=trixie
# Debian architecture (amd64, arm64, armhf), set by build script
ARG PACKAGE_ARCH
# Dotnet architeture (x64, arm64, arm), set by build script
ARG DOTNET_ARCH
# Base Image architecture (amd64, arm64v8, arm32v7), set by build script
ARG IMAGE_ARCH
# Target platform architecture (amd64, arm64/v8, arm/v7), set by build script
ARG TARGET_ARCH

# Jellyfin version
ARG JELLYFIN_VERSION

#
# Build the web artifacts
#
FROM node:${NODEJS_VERSION}-alpine AS web

ARG SOURCE_DIR=/src
ARG ARTIFACT_DIR=/web

ARG JELLYFIN_VERSION
ENV JELLYFIN_VERSION=${JELLYFIN_VERSION}

RUN apk add \
    autoconf \
    g++ \
    make \
    libpng-dev \
    gifsicle \
    alpine-sdk \
    automake \
    libtool \
    gcc \
    musl-dev \
    nasm \
    python3 \
    git \
 && git config --global --add safe.directory /jellyfin/jellyfin-web

WORKDIR ${SOURCE_DIR}
COPY jellyfin-web .

RUN npm ci --no-audit --unsafe-perm \
 && npm run build:production \
 && mv dist ${ARTIFACT_DIR}
 
# Combined image version (Debian)
ARG OS_VERSION=trixie




#
# Build the server artifacts
#
FROM debian:${OS_VERSION}-slim AS server

ARG DOTNET_ARCH
ARG DOTNET_VERSION

ARG SOURCE_DIR=/src
ARG ARTIFACT_DIR=/server

ARG CONFIG=Release
ENV CONFIG=${CONFIG}

WORKDIR ${SOURCE_DIR}

COPY jellyfin-server .
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests --yes \
    curl \
    ca-certificates \
    libicu76

RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
 && sed -i 's/tar -xzf "\$zip_path" -C "\$temp_out_path" > \/dev\/null || failed=true/tar --no-same-permissions -xzf "\$zip_path" -C "\$temp_out_path"/g' dotnet-install.sh \
 && chmod +x dotnet-install.sh

RUN bash dotnet-install.sh --channel ${DOTNET_VERSION} --install-dir /usr/local/bin

RUN dotnet publish Jellyfin.Server --arch ${DOTNET_ARCH} --configuration ${CONFIG} \
    --output="${ARTIFACT_DIR}" --self-contained \
    -p:DebugSymbols=false -p:DebugType=none
	
# Install jellyfin-ffmpeg dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    autoconf \
    automake \
    cmake \
    libtool \
    nasm \
    yasm \
    python3 \
    python3-distutils-extra \
    python3-setuptools \
    wget \
    curl \
	libgmp-dev \
    libicu76 \
    libchromaprint-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libgnutls28-dev \
    libgmp-dev \
	libass-dev \
	libbluray-dev \
	libdav1d-dev \
	libmp3lame-dev \
	libopenmpt-dev \
	libopus-dev \
	libtheora-dev \
	libvpx-dev \
	libwebp-dev \
	libx264-dev \
	libx265-dev \
	libzimg-dev \
    libzvbi-dev \
	libdrm-dev \
	ocl-icd-opencl-dev \
    pkg-config


# libfdk-aac
WORKDIR /tmp
RUN curl -LO https://downloads.sourceforge.net/opencore-amr/fdk-aac-2.0.2.tar.gz \
  && tar --no-same-permissions -xzf fdk-aac-2.0.2.tar.gz || true
RUN cd fdk-aac-2.0.2 \
  && ./configure --host=arm-linux-gnueabihf --prefix=/usr/local \
  && make -j$(nproc) \
  && make install


# SV1
WORKDIR /tmp
RUN git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git
RUN cd SVT-AV1 && mkdir build && cd build \
  && cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_SHARED=ON \
  && make -j$(nproc) \
  && make install



# Clone source
WORKDIR ${SOURCE_DIR}
RUN git clone https://github.com/jellyfin/jellyfin-ffmpeg.git
WORKDIR ${SOURCE_DIR}/jellyfin-ffmpeg

# Configure & build ffmpeg with Jellyfin settings
RUN ./configure \
    --prefix=/usr/lib/jellyfin-ffmpeg \
    --target-os=linux \
    --extra-version=Jellyfin \
    --disable-doc \
    --disable-ffplay \
    --disable-ptx-compression \
    --disable-static \
    --disable-libxcb \
    --disable-sdl2 \
    --disable-xlib \
	--enable-nonfree \
    --enable-lto=auto \
    --enable-gpl \
    --enable-version3 \
    --enable-shared \
    --enable-gmp \
    --enable-gnutls \
    --enable-chromaprint \
    --enable-opencl \
    --enable-libdrm \
    --enable-libxml2 \
    --enable-libass \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libfontconfig \
    --enable-libharfbuzz \
    --enable-libbluray \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libopenmpt \
    --enable-libdav1d \
    --enable-libsvtav1 \
    --enable-libwebp \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libzvbi \
    --enable-libzimg \
    --enable-libfdk-aac \
    --arch=armhf \
    --cross-prefix=/usr/bin/arm-linux-gnueabihf- \
    --toolchain=hardened \
    --enable-cross-compile \
  && make -j$(nproc) \
  && make install






#
# Build the final combined image
#
FROM --platform=linux/${TARGET_ARCH} ${IMAGE_ARCH}/debian:${OS_VERSION}-slim AS combined

ARG OS_VERSION
ARG PACKAGE_ARCH

# Set the health URL
ENV HEALTHCHECK_URL=http://localhost:8096/health

# Default environment variables for the Jellyfin invocation
ENV DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    JELLYFIN_DATA_DIR="/config" \
    JELLYFIN_CACHE_DIR="/cache" \
    JELLYFIN_CONFIG_DIR="/config/config" \
    JELLYFIN_LOG_DIR="/config/log" \
    JELLYFIN_WEB_DIR="/jellyfin/jellyfin-web" \
    JELLYFIN_FFMPEG="/usr/lib/jellyfin-ffmpeg/ffmpeg"

# required for fontconfig cache
ENV XDG_CACHE_HOME=${JELLYFIN_CACHE_DIR}

# https://github.com/dlemstra/Magick.NET/issues/707#issuecomment-785351620
ENV MALLOC_TRIM_THRESHOLD_=131072

# https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(Native-GPU-Support)
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# Install dependencies:
RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests --yes \
    ca-certificates \
    gnupg \
    curl \
 && curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg \
 && cat <<EOF > /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/debian
Suites: ${OS_VERSION}
Components: main
Architectures: ${PACKAGE_ARCH}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF

RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests --yes \
    openssl \
    locales \
    libicu76 \
    libfontconfig1 \
    libfreetype6 \
    libjemalloc2 \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
 && apt-get remove gnupg apt-transport-https --yes \
 && apt-get clean autoclean --yes \
 && apt-get autoremove --yes \
 && rm -rf /var/cache/apt/archives* /var/lib/apt/lists/*

 
COPY --from=server /usr/lib/jellyfin-ffmpeg/bin/ffmpeg /usr/lib/jellyfin-ffmpeg/ffmpeg
COPY --from=server /usr/lib/jellyfin-ffmpeg/bin/ffprobe /usr/lib/jellyfin-ffmpeg/ffprobe
COPY --from=server /usr/lib/jellyfin-ffmpeg/lib /usr/lib/jellyfin-ffmpeg/lib

COPY --from=server /usr/lib/arm-linux-gnueabihf/*.so* /usr/lib/arm-linux-gnueabihf/
COPY --from=server /usr/local/lib/*.so* /usr/local/lib/

COPY --from=server /server /jellyfin
COPY --from=web /web /jellyfin/jellyfin-web

RUN ldconfig

RUN mkdir -p /usr/lib/jellyfin \
  && ln -s /usr/lib/arm-linux-gnueabihf/libjemalloc.so.2 /usr/lib/jellyfin/libjemalloc.so.2

# Set LD_PRELOAD to use the linked jemalloc library
ENV LD_PRELOAD=/usr/lib/jellyfin/libjemalloc.so.2

ENV LD_LIBRARY_PATH=/usr/lib/jellyfin-ffmpeg/lib:$LD_LIBRARY_PATH

RUN mkdir -p ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
 && chmod 777 ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}
 
EXPOSE 8096
VOLUME ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}
ENTRYPOINT ["/jellyfin/jellyfin"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 \
     CMD curl --noproxy 'localhost' -Lk -fsS "${HEALTHCHECK_URL}" || exit 1
