#!/usr/bin/env bash
set -e

SDKMAN_DIR="$HOME/.sdkman"
SDKMAN_SCRIPT="$SDKMAN_DIR/bin/sdkman-init.sh"

if [[ -d "$SDKMAN_DIR" ]] && [[ -s "$SDKMAN_SCRIPT" ]]; then
  echo "==> SDKMAN already installed, skipping installer"
else
  echo "==> Installing SDKMAN..."
  curl -s "https://get.sdkman.io?ci=true" | bash
fi

# Source SDKMAN to use it immediately
source "$SDKMAN_SCRIPT"

# Install Amazon Corretto LTS (latest available)
echo "==> Installing Amazon Corretto (Java LTS)..."
JAVA_VERSION=$(SDKMAN_COLOUR=false sdk list java 2>/dev/null \
  | grep -E '\bamzn\b' \
  | grep 'LTS' \
  | head -1 \
  | awk '{print $NF}')
if sdk list java | grep -q "installed.*${JAVA_VERSION}"; then
  echo "==> Java $JAVA_VERSION already installed, skipping"
else
  sdk install java "$JAVA_VERSION"
fi
sdk default java "$JAVA_VERSION"

# Install additional candidates as needed
echo ""
read -p "Install Gradle? (Y/n) " -r gradle_response
gradle_response=${gradle_response:-Y}
if [[ "$gradle_response" =~ ^[Yy]$ ]]; then
  sdk install gradle
fi

read -p "Install Maven? (Y/n) " -r maven_response
maven_response=${maven_response:-Y}
if [[ "$maven_response" =~ ^[Yy]$ ]]; then
  sdk install maven
fi
