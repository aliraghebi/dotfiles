#!/usr/bin/env bash

# get.docker.com installs the docker-ce package — upgrade it through apt
upgrade_apt() {
  require_apt docker-ce
}
