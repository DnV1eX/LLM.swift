#!/bin/bash

set -e

LLAMA_CPP_DIR="llama.cpp"
GITHUB_REPO="ggml-org/llama.cpp"
ASSET_PATTERN="-xcframework.zip"
DOWNLOAD_DIR="."

echo "Finding the latest release asset URL for $GITHUB_REPO..."
ASSET_URL=$(curl -s https://api.github.com/repos/$GITHUB_REPO/releases/latest | jq -r --arg pattern "$ASSET_PATTERN" '.assets[] | select(.name | endswith($pattern)) | .browser_download_url')

if [ -z "$ASSET_URL" ]; then
  echo "Error: Could not find a release asset matching '$ASSET_PATTERN' in the latest release of $GITHUB_REPO."
  exit 1
fi

ASSET_NAME=$(basename "$ASSET_URL")
DOWNLOAD_PATH="$DOWNLOAD_DIR/$ASSET_NAME"

echo "Downloading $ASSET_NAME from $ASSET_URL..."
curl -L "$ASSET_URL" -o "$DOWNLOAD_PATH"

echo "Removing existing $LLAMA_CPP_DIR directory..."
rm -rf "$LLAMA_CPP_DIR"

echo "Creating $LLAMA_CPP_DIR directory..."
mkdir -p "$LLAMA_CPP_DIR"

echo "Unzipping $ASSET_NAME into $LLAMA_CPP_DIR..."
unzip -q "$DOWNLOAD_PATH" -d "$LLAMA_CPP_DIR"

if [ $(ls -1 "$LLAMA_CPP_DIR" | wc -l) -eq 1 ] && [ -d "$LLAMA_CPP_DIR/$(ls -1 "$LLAMA_CPP_DIR")" ]; then
    echo "Moving contents from nested directory..."
    NESTED_DIR="$LLAMA_CPP_DIR/$(ls -1 "$LLAMA_CPP_DIR")"
    shopt -s dotglob nullglob
    mv "$NESTED_DIR"/* "$LLAMA_CPP_DIR/"
    shopt -u dotglob nullglob
    rm -rf "$NESTED_DIR"
fi

read -r -p "Remove debug symbols from llama.xcframework? They may exceed GitHub's 100MB file size limit if committed. (y/N): " reply
if [[ $reply =~ ^[Yy]$ ]]; then
  echo "Removing dSYMs folders and DebugSymbolsPath keys in Info.plist..."
  rm -rf "$LLAMA_CPP_DIR"/llama.xcframework/*/dSYMs
  INFO_PLIST="$LLAMA_CPP_DIR/llama.xcframework/Info.plist"
  plutil -convert json -o - "$INFO_PLIST" | jq '.AvailableLibraries |= map(del(.DebugSymbolsPath))' | plutil -convert xml1 -o "$INFO_PLIST" -
fi

echo "Cleaning up downloaded file $DOWNLOAD_PATH..."
rm "$DOWNLOAD_PATH"

read -r -p "Run Swift tests? Be aware that they initiate download of large model files. (y/N): " reply
if [[ $reply =~ ^[Yy]$ ]]; then
  echo "Running Swift tests..."
  swift test
else
  echo "Skipping tests."
fi
