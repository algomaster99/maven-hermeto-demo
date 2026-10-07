#!/usr/bin/env bash
# demo-magic version of the README steps. Press ENTER to type each command and
# ENTER again to run it. -d disables simulated typing (no pv needed).
#
# Step 1 needs network, so it is faked: the command is only typed, and the
# output recorded by record-01.sh is replayed. The rest runs for real.

cd "$(dirname "${BASH_SOURCE[0]}")"
. ../vendor/demo-magic/demo-magic.sh

if [[ ! -f go-offline.log || ! -d sandbox ]]; then
  echo "Missing go-offline.log or sandbox/. Run ./record-01.sh first (needs network)." >&2
  exit 1
fi

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

clear

p "# Prefetch everything Maven can see into an empty local repo"
p 'mvn -f ../01-project/pom.xml -Dmaven.repo.local=$(pwd)/sandbox dependency:go-offline'
cat go-offline.log

p "# Now run the tests offline, using only that repo"
pe 'mvn -o -f ../01-project/pom.xml -Dmaven.repo.local=$(pwd)/sandbox test'
