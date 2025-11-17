#!/bin/bash

set -e  # Exit immediately if a command fails

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <JELLYFIN_VERSION> (ex: 10.11.3)"
    exit 1
fi

# Jellyfin version
JF_VER="$1"
JELLYFIN_VERSION="v$JF_VER"

echo "Using Jellyfin version: $JELLYFIN_VERSION"


# Define URLs and target directories using the version variable
WEB_URL="https://github.com/jellyfin/jellyfin-web/archive/refs/tags/${JELLYFIN_VERSION}.tar.gz"
WEB_DIR="jellyfin-web"
rm -rf $WEB_DIR

SERVER_URL="https://github.com/jellyfin/jellyfin/archive/refs/tags/${JELLYFIN_VERSION}.tar.gz"
SERVER_DIR="jellyfin-server"
rm -rf $SERVER_DIR

# Download and extract Jellyfin Web
echo "Downloading Jellyfin Web..."
wget -O "${JELLYFIN_VERSION}-web.tar.gz" "$WEB_URL"
echo "Extracting to $WEB_DIR..."
mkdir -p "$WEB_DIR"
tar -xzf "${JELLYFIN_VERSION}-web.tar.gz" --strip-components=1 -C "$WEB_DIR"
rm "${JELLYFIN_VERSION}-web.tar.gz"

# Download and extract Jellyfin Server
echo "Downloading Jellyfin Server..."
wget -O "${JELLYFIN_VERSION}-server.tar.gz" "$SERVER_URL"
echo "Extracting to $SERVER_DIR..."
mkdir -p "$SERVER_DIR"
tar -xzf "${JELLYFIN_VERSION}-server.tar.gz" --strip-components=1 -C "$SERVER_DIR"
rm "${JELLYFIN_VERSION}-server.tar.gz"

echo "Done!"

exit 0