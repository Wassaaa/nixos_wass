#!/usr/bin/env bash
# Script to update NordVPN CLI and GUI versions and hashes

set -euo pipefail

CLI_MODULE_FILE="@cliModuleFile@"
GUI_MODULE_FILE="@guiModuleFile@"
PACKAGES_URL="https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/main/binary-amd64/Packages"

echo "Fetching latest NordVPN versions..."

# Fetch the Packages file and extract both CLI and GUI info
PACKAGE_DATA=$(curl -sL "$PACKAGES_URL")

# Extract CLI package info
CLI_INFO=$(echo "$PACKAGE_DATA" | awk '
  /^Package: nordvpn$/ { in_package=1; next }
  in_package && /^Version:/ { version=$2 }
  in_package && /^SHA256:/ { sha=$2 }
  in_package && /^Filename:/ && version && sha {
    print version " " sha
    version=""; sha=""; in_package=0
  }
' | tail -1)

# Extract GUI package info
GUI_INFO=$(echo "$PACKAGE_DATA" | awk '
  /^Package: nordvpn-gui$/ { in_package=1; next }
  in_package && /^Version:/ { version=$2 }
  in_package && /^SHA256:/ { sha=$2 }
  in_package && /^Filename:/ && version && sha {
    print version " " sha
    version=""; sha=""; in_package=0
  }
' | tail -1)

CLI_NEW_VERSION=$(echo "$CLI_INFO" | awk '{print $1}')
CLI_NEW_SHA=$(echo "$CLI_INFO" | awk '{print $2}')
GUI_NEW_VERSION=$(echo "$GUI_INFO" | awk '{print $1}')
GUI_NEW_SHA=$(echo "$GUI_INFO" | awk '{print $2}')

if [ -z "$CLI_NEW_VERSION" ] || [ -z "$CLI_NEW_SHA" ]; then
  echo "Error: Could not fetch CLI version or SHA256"
  exit 1
fi

if [ -z "$GUI_NEW_VERSION" ] || [ -z "$GUI_NEW_SHA" ]; then
  echo "Error: Could not fetch GUI version or SHA256"
  exit 1
fi

# Get current versions from the module files
CLI_CURRENT_VERSION=$(grep 'version = "' "$CLI_MODULE_FILE" | head -1 | sed 's/.*version = "\(.*\)";.*/\1/')
GUI_CURRENT_VERSION=$(grep 'version = "' "$GUI_MODULE_FILE" | head -1 | sed 's/.*version = "\(.*\)";.*/\1/')

echo "NordVPN CLI:"
echo "  Current version: $CLI_CURRENT_VERSION"
echo "  Latest version:  $CLI_NEW_VERSION"
echo "  Latest SHA256:   $CLI_NEW_SHA"
echo ""
echo "NordVPN GUI:"
echo "  Current version: $GUI_CURRENT_VERSION"
echo "  Latest version:  $GUI_NEW_VERSION"
echo "  Latest SHA256:   $GUI_NEW_SHA"

echo ""
echo "NordVPN GUI:"
echo "  Current version: $GUI_CURRENT_VERSION"
echo "  Latest version:  $GUI_NEW_VERSION"
echo "  Latest SHA256:   $GUI_NEW_SHA"

CLI_NEEDS_UPDATE=false
GUI_NEEDS_UPDATE=false

if [ "$CLI_CURRENT_VERSION" != "$CLI_NEW_VERSION" ]; then
  CLI_NEEDS_UPDATE=true
fi

if [ "$GUI_CURRENT_VERSION" != "$GUI_NEW_VERSION" ]; then
  GUI_NEEDS_UPDATE=true
fi

if [ "$CLI_NEEDS_UPDATE" = false ] && [ "$GUI_NEEDS_UPDATE" = false ]; then
  echo ""
  echo "✓ Both packages are already up to date!"
  exit 0
fi

echo ""
if [ "$CLI_NEEDS_UPDATE" = true ] && [ "$GUI_NEEDS_UPDATE" = true ]; then
  read -p "Update both CLI and GUI to latest versions? [y/N] " -n 1 -r
elif [ "$CLI_NEEDS_UPDATE" = true ]; then
  read -p "Update CLI to version $CLI_NEW_VERSION? [y/N] " -n 1 -r
else
  read -p "Update GUI to version $GUI_NEW_VERSION? [y/N] " -n 1 -r
fi
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Update cancelled."
  exit 0
fi

# Update CLI if needed
if [ "$CLI_NEEDS_UPDATE" = true ]; then
  sed -i "s/version = \"$CLI_CURRENT_VERSION\";/version = \"$CLI_NEW_VERSION\";/" "$CLI_MODULE_FILE"
  sed -i "s/sha256 = \".*\";/sha256 = \"$CLI_NEW_SHA\";/" "$CLI_MODULE_FILE"
  echo "✓ Updated CLI: $CLI_MODULE_FILE"
  echo "    version: $CLI_CURRENT_VERSION → $CLI_NEW_VERSION"
fi

# Update GUI if needed
if [ "$GUI_NEEDS_UPDATE" = true ]; then
  sed -i "s/version = \"$GUI_CURRENT_VERSION\";/version = \"$GUI_NEW_VERSION\";/" "$GUI_MODULE_FILE"
  sed -i "s/sha256 = \".*\";/sha256 = \"$GUI_NEW_SHA\";/" "$GUI_MODULE_FILE"
  echo "✓ Updated GUI: $GUI_MODULE_FILE"
  echo "    version: $GUI_CURRENT_VERSION → $GUI_NEW_VERSION"
fi

echo ""
echo "Next steps:"
echo "  1. Review the changes:"
if [ "$CLI_NEEDS_UPDATE" = true ]; then
  echo "     git diff $CLI_MODULE_FILE"
fi
if [ "$GUI_NEEDS_UPDATE" = true ]; then
  echo "     git diff $GUI_MODULE_FILE"
fi
echo "  2. Test the build: sudo nixos-rebuild test"
echo "  3. If it works: sudo nixos-rebuild switch"
