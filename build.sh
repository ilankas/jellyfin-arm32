#/bin/bash

JF_VER=10.11.3   # 17/11/2025

./download_artifacts.sh $JF_VER

docker build --progress=plain --no-cache \
  --build-arg PACKAGE_ARCH=armhf \
  --build-arg DOTNET_ARCH=arm \
  --build-arg IMAGE_ARCH=arm32v7 \
  --build-arg TARGET_ARCH=arm/v7 \
  --build-arg JELLYFIN_VERSION=$JF_VER \
  --build-arg CONFIG=Release \
  --build-arg DOTNET_VERSION=9.0 \
  --build-arg NODEJS_VERSION=20 \
  --file /mnt/usb/Git/jellyfin-arm32/Dockerfile \
  --tag jellyfin/jellyfin:$JF_VER-arm32v7 /mnt/usb/Git/jellyfin-arm32

