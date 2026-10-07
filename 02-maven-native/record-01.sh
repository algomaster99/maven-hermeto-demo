#!/usr/bin/env bash
# Run before the talk, on a good network. Fills a fresh sandbox/ with
# go-offline and saves its output, so demo-01.sh can replay step 1 without
# depending on the venue network.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf sandbox
mvn -f ../01-project/pom.xml -Dmaven.repo.local="$(pwd)/sandbox" -Dstyle.color=always \
  dependency:go-offline | tee go-offline.log
