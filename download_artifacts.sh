#!/bin/bash
set -e  # Exit immediately if a command fails

# Jellyfin version
JELLYFIN_VERSION="v10.11.2"

# Define URLs and target directories using the version variable
WEB_URL="https://github.com/jellyfin/jellyfin-web/archive/refs/tags/${JELLYFIN_VERSION}.tar.gz"
WEB_DIR="jellyfin-web"

SERVER_URL="https://github.com/jellyfin/jellyfin/archive/refs/tags/${JELLYFIN_VERSION}.tar.gz"
SERVER_DIR="jellyfin-server"

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
