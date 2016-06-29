#!/usr/bin/env bash

LYP_VERSION="1.0.0"
WORKDIR="/tmp/lyp-release-installer"
URL_BASE="https://github.com/noteflakes/lyp/releases/download/v$LYP_VERSION"

shopt -s extglob
set -o errtrace
set -o errexit

fail() { log "\nERROR: $*\n" ; exit 1 }
has() { type "$1" > /dev/null 2>&1 }

download() {
  if has "curl"; then
    curl -L -o $*
  elif has "wget"; then
    wget -O $*
  else
    fail "Could not find curl or wget"
  fi
}

PLATFORM=`uname -sp`
case $PLATFORM in
  "Linux x86_64")
    RELEASE_FILE="lyp-$LYP_VERSION-linux-x86_64"
    ;;
  "Linux x86")
    RELEASE_FILE="lyp-$LYP_VERSION-linux-x86"
    ;;
  "Darwin i386")
    RELEASE_FILE="lyp-$LYP_VERSION-osx"
    ;;
  *)
    fail "Unspported platform $PLATFORM"
esac

RELEASE_URL="$URL_BASE/$RELEASE_FILE.tar.gz"
RELEASE_PATH="$WORKDIR/$RELEASE_FILE"

rm -rf $WORKDIR
mkdir $WORKDIR
echo "Downloading $RELEASE_URL"
download "$WORKDIR/release.tar.gz" $RELEASE_URL
echo "Extracting $WORKDIR/release.tar.gz"
tar -xzf "$WORKDIR/release.tar.gz" -C $WORKDIR

$RELEASE_PATH/bin/lyp install self

rm -rf $WORKDIR
