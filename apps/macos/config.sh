#!/usr/bin/env bash
# macOS system defaults

step "Applying macOS defaults"

# Close any open System Preferences panes to prevent overrides
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# ── Siri ─────────────────────────────────────────────────────────────────────
defaults write com.apple.assistant.support 'Assistant Enabled' -bool false
defaults write com.apple.assistant.backedup 'Use device speaker for TTS' -int 3
defaults write com.apple.SetupAssistant 'DidSeeSiriSetup' -bool true
defaults write com.apple.systemuiserver 'NSStatusItem Visible Siri' 0
defaults write com.apple.Siri 'StatusMenuVisible' -bool false
defaults write com.apple.Siri 'UserHasDeclinedEnable' -bool true
defaults write com.apple.assistant.support 'Siri Data Sharing Opt-In Status' -int 2

# ── General UI/UX ─────────────────────────────────────────────────────────────
# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Disable "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# ── Keyboard ──────────────────────────────────────────────────────────────────
# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Cmd+H / Cmd+L to move between Spaces
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>104</integer><integer>4</integer><integer>1048576</integer></array></dict></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>108</integer><integer>37</integer><integer>1048576</integer></array></dict></dict>"

# Disable Ctrl+Space input source switching (conflicts with tmux)
/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist \
    -c "Set AppleSymbolicHotKeys:60:enabled false" 2>/dev/null || true
/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist \
    -c "Set AppleSymbolicHotKeys:61:enabled false" 2>/dev/null || true

# Apply keyboard shortcut changes
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# ── Spotlight ─────────────────────────────────────────────────────────────────
# Search Applications only — disable all other categories
defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 0;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 0;"name" = "DIRECTORIES";}' \
    '{"enabled" = 0;"name" = "PDF";}' \
    '{"enabled" = 0;"name" = "FONTS";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# ── Dock ──────────────────────────────────────────────────────────────────────
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock expose-group-apps -bool true

# ── Menu Bar Clock ────────────────────────────────────────────────────────────
defaults write com.apple.menuextra.clock ShowDate -int 1
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock Show24Hour -bool false
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
defaults write com.apple.menuextra.clock ShowSeconds -bool false

# ── Control Center ────────────────────────────────────────────────────────────
# Bluetooth: show in menu bar
defaults -currentHost write com.apple.controlcenter Bluetooth -int 18
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

# Sound: always show in menu bar
defaults -currentHost write com.apple.controlcenter Sound -int 18
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true

# Battery: show in menu bar & control center, with percentage
defaults -currentHost write com.apple.controlcenter Battery -int 3
defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# ── Finder ────────────────────────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# New windows open to ~/Downloads
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file:///$HOME/Downloads"

# No .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Screenshots ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"

# ── Locale & Language ─────────────────────────────────────────────────────────
defaults write NSGlobalDomain AppleLocale -string en_US
defaults write NSGlobalDomain AppleLanguages -array "en-US" "fa-IR"

# ── Login ─────────────────────────────────────────────────────────────────────
# Suppress "Last login" message in new terminal windows
touch ~/.hushlogin

# ── Restart affected applications ─────────────────────────────────────────────
killall cfprefsd 2>/dev/null || true
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

ok "macOS defaults applied"

if ! command_exists brew; then
  printf "  Install Homebrew now? [y/N] "
  read -r _brew_reply
  if [[ "$_brew_reply" =~ ^[Yy]$ ]]; then
    cmd_install brew
  fi
fi
