#!/usr/bin/env bash
# demo-magic version of the README steps. Press ENTER to type each command and
# ENTER again to run it. -d disables simulated typing (no pv needed).
#
# Lockfile generation and fetch-deps need network, so they are faked: the
# commands are only typed, and the output recorded by record-02.sh is
# replayed. The rest runs for real.

cd "$(dirname "${BASH_SOURCE[0]}")"
. ../vendor/demo-magic/demo-magic.sh

if [[ ! -f generate.log || ! -f fetch-deps.log || ! -d output ]]; then
  echo "Missing recorded logs or output/. Run ./record-02.sh first (needs network)." >&2
  exit 1
fi

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

clear

p "# Create maven lockfile"
p 'mvn -f ../01-project/pom.xml test io.github.chains-project:maven-lockfile:5.18.4:generate -Dhermetic -DchecksumMode=local'
cat generate.log

p "# The artifact surefire resolved on the fly is now recorded"
pe "jq '.. | objects | select(.artifactId == \"surefire-junit-platform\")' ../01-project/lockfile.json"

p "# Prefetch and checksum-verify everything in the lockfile"
p "./hermeto fetch-deps --source ../01-project --output ./output '{\"type\": \"x-maven\", \"path\": \".\"}'"
cat fetch-deps.log

p "# Write the settings.xml that points Maven at the prefetched repo"
pe './hermeto inject-files ./output'

p "# Now run the tests offline, using only that repo"
pe 'mvn -o -s ./output/settings.xml -f ../01-project/pom.xml test -Dmaven.test.skip=false'
