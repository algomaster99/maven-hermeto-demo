#!/usr/bin/env bash
# Run before the talk, on a good network. Regenerates the lockfile and fills a
# fresh output/ with fetch-deps, saving the output of each, so demo-02.sh can
# replay them without depending on the venue network.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

mvn -f ../01-project/pom.xml -Dstyle.color=always \
  test io.github.chains-project:maven-lockfile:5.18.4:generate -Dhermetic -DchecksumMode=local \
  | tee generate.log

rm -rf output
./hermeto fetch-deps --source ../01-project --output ./output \
  '{"type": "x-maven", "path": "."}' 2>&1 | tee fetch-deps.log
