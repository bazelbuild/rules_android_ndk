#!/bin/bash
# Download a specific release of the NDK for all three platforms and calculate SHA256 checksums
# to add to the sha256sums.bzl file.
set -eu

ndk_version=$1

cd "$(mktemp -d)"
echo "Working in $PWD"

curl -LO "https://dl.google.com/android/repository/android-ndk-${ndk_version}-windows.zip"
curl -LO "https://dl.google.com/android/repository/android-ndk-${ndk_version}-darwin.zip"
curl -LO "https://dl.google.com/android/repository/android-ndk-${ndk_version}-linux.zip"
sha256sum ./*