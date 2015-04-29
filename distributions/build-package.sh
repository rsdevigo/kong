#!/bin/bash

set -o errexit

# Check system
if ! [ "$(uname)" = "Darwin" ]; then
  echo "Run this script from OS X"
  exit 1
fi

supported_platforms=( centos:5 centos:6 centos:7 debian:6 debian:7 debian:8 ubuntu:12.04.5 ubuntu:14.04.2 ubuntu:15.04 osx )
platforms_to_build=( )

for var in "$@"
do
  if [[ "all" == "$var" ]]; then
    platforms_to_build=( "${supported_platforms[@]}" )
  elif ! [[ " ${supported_platforms[*]} " == *" $var "* ]]; then
    echo "[ERROR] \"$var\" not supported. Supported platforms are: "$( IFS=$'\n'; echo "${supported_platforms[*]}" )
    echo "You can optionally specify \"all\" to build all the supported platforms"
    exit 1
  else
    platforms_to_build+=($var)
  fi
done

if [ ${#platforms_to_build[@]} -eq 0 ]; then
  echo "Please specify an argument!"
  exit 1
fi

echo "Building "$( IFS=$'\n'; echo "${platforms_to_build[*]}" )

# Preparing environment
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Current directory is: "$DIR
if [ "$DIR" == "/" ]; then
  DIR=""
fi

# Delete previous packages
rm -rf $DIR/build-output

# Start build
for i in "${platforms_to_build[@]}"
do
  echo "Building for $i"
  if [[ "$i" == "osx" ]]; then
    /bin/bash $DIR/build-package-script.sh
  else
    docker run -v $DIR/:/build-data $i /bin/bash /build-data/build-package-script.sh
  fi
done