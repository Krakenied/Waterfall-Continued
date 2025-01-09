#!/usr/bin/env bash

./scripts/applyPatches.sh || exit 1

if [[ ! -z "${BUILD_NUMBER}" ]]; then
    build_number="${BUILD_NUMBER}"
else
    build_number="unknown"
fi

echo "Running with build number set to $build_number"

if [ "$1" == "--jar" ]; then
     mvn clean package -Dbuild.number=$build_number
fi
