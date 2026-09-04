#!/usr/bin/env bash
# Builds a local venv for the hermeto submodule (vendor/hermeto) so the demo
# doesn't depend on hermeto being installed system-wide, and upstream doesn't
# publish a standalone binary. Run once after `git submodule update --init`.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -d hermeto/.git ] && [ ! -f hermeto/pyproject.toml ]; then
  echo "vendor/hermeto is empty — run 'git submodule update --init' first." >&2
  exit 1
fi

python3 -m venv venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r hermeto/requirements-extras.txt
venv/bin/pip install --no-deps -e ./hermeto

echo "hermeto installed: $(venv/bin/hermeto --version)"
