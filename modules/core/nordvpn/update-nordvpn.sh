#!/usr/bin/env bash
# Script to update NordVPN version and hash in the nordvpn.nix module

set -euo pipefail

MODULE_FILE="@moduleFile@"
PACKAGES_URL="https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/main/binary-amd64/Packages"

echo "Fetching latest NordVPN version..."

# Fetch the Packages file and extract the latest version and SHA256
PACKAGE_INFO=$(curl -sL "$PACKAGES_URL" | awk '
  /^Package: nordvpn$/ { in_package=1; next }
  in_package && /^Version:/ { version=$2 }
  in_package && /^SHA256:/ { sha=$2 }
  in_package && /^Filename:/ && version && sha {
    print version " " sha
    version=""; sha=""; in_package=0
  }
' | tail -1)

NEW_VERSION=$(echo "$PACKAGE_INFO" | awk '{print $1}')
NEW_SHA=$(echo "$PACKAGE_INFO" | awk '{print $2}')

if [ -z "$NEW_VERSION" ] || [ -z "$NEW_SHA" ]; then
  echo "Error: Could not fetch version or SHA256"
  exit 1
fi

# Get current version from the module file
CURRENT_VERSION=$(grep 'version = "' "$MODULE_FILE" | head -1 | sed 's/.*version = "\(.*\)";.*/\1/')

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $NEW_VERSION"
echo "Latest SHA256:   $NEW_SHA"

if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
  echo "✓ Already up to date!"
  exit 0
fi

echo ""
read -p "Update to version $NEW_VERSION? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Update cancelled."
  exit 0
fi

# Update the version
sed -i "s/version = \"$CURRENT_VERSION\";/version = \"$NEW_VERSION\";/" "$MODULE_FILE"

# Update the sha256
sed -i "s/sha256 = \".*\";/sha256 = \"$NEW_SHA\";/" "$MODULE_FILE"

echo "✓ Updated $MODULE_FILE"
echo ""
echo "Changes made:"
echo "  version: $CURRENT_VERSION → $NEW_VERSION"
echo "  sha256:  $NEW_SHA"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff $MODULE_FILE"
echo "  2. Test the build: sudo nixos-rebuild test"
echo "  3. If it works: sudo nixos-rebuild switch"
