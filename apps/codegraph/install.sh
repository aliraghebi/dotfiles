#!/usr/bin/env bash
set -euo pipefail

install() {
  require_npm "@colbymchenry/codegraph" codegraph
}
