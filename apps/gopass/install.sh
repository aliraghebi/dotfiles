#!/usr/bin/env bash

install_brew() {
  require_brew gopass
  require_brew gopass-jsonapi
}

install() {
  # macOS: handled by install_brew above
  is_macos && return 0

  require_gh_release "gopasspw/gopass" "gopass" 'gopass_${version#v}_linux_amd64.deb'
}
