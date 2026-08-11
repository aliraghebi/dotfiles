#!/usr/bin/env bash
APP_OS="macos"
# The `orb` CLI lives in ~/.orbstack/bin, which only lands on PATH after the app
# has been launched once, so a binary check here would fail on a fresh install.
APP_BINARY=""
APP_DESCRIPTION="OrbStack — fast Docker and Linux VMs, Docker Desktop replacement"
APP_DEPS=()
APP_CONFIGS=()
