docker build --progress=plain --no-cache \
  --build-arg PACKAGE_ARCH=armhf \
  --build-arg DOTNET_ARCH=arm \
  --build-arg IMAGE_ARCH=arm32v7 \
  --build-arg TARGET_ARCH=arm/v7 \
  --build-arg JELLYFIN_VERSION=10.11.2 \
  --build-arg CONFIG=Release \
  --build-arg DOTNET_VERSION=9.0 \
  --build-arg NODEJS_VERSION=20 \
  --file /mnt/usb/Git/jellyfin-arm32/DockerfileServer \
  --tag jellyfin/jellyfin-server /mnt/usb/Git/jellyfin-arm32

