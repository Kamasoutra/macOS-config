#!/bin/zsh

# ─────────────────────────────────────────────────────────────────────────────
# MACHINE TYPE  (arg 1 optionnel : "pro" | "perso")
# ─────────────────────────────────────────────────────────────────────────────

if [ "$1" = "pro" ]; then
  IS_PRO=true
elif [ "$1" = "perso" ]; then
  IS_PRO=false
else
  echo '\n👨‍🚀 Quel type de machine ?'
  echo '    1) Perso'
  echo '    2) Pro'
  read -p '    -> ' MACHINE_TYPE
  [ "$MACHINE_TYPE" = "2" ] && IS_PRO=true || IS_PRO=false
fi

# ─────────────────────────────────────────────────────────────────────────────
# VARIABLES  (arg 2 optionnel : chemin vers le fichier de variables)
# Fallback : Bitwarden > argument > iCloud > USB > prompt interactif
# ─────────────────────────────────────────────────────────────────────────────

ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
[ "$IS_PRO" = true ] && USB_CONFIG="/Volumes/Kama-encrypted/#pro/macOS-config-variables" \
                     || USB_CONFIG="/Volumes/Kama-encrypted/#Kama/macOS-config-variables"
ICLOUD_CONFIG="$ICLOUD_DIR/macOS-config-variables"
BW_ITEM_NAME="macOS-config-variables"

_load_from_bitwarden() {
  # Installe bw CLI si absent (bootstrap)
  if ! command -v bw &>/dev/null; then
    echo '    Installing Bitwarden CLI...'
    brew install bitwarden-cli
  fi

  # Réutilise la session du zshrc si encore valide
  if [ -n "$BW_SESSION" ] && bw unlock --check --session "$BW_SESSION" &>/dev/null; then
    echo '    Bitwarden : session active réutilisée'
  else
    # Demande les infos de connexion (ne peuvent pas venir du vault)
    echo '\n👨‍🚀 Configuration Bitwarden :'
    DEFAULT_BW_SERVER=$(bw config server 2>/dev/null | grep -v 'https://vault.bitwarden.com' | head -1)
    read -p "    - server URL [${DEFAULT_BW_SERVER:-https://vault.bitwarden.com}] : " BW_SERVER
    BW_SERVER="${BW_SERVER:-${DEFAULT_BW_SERVER:-https://vault.bitwarden.com}}"
    read -p "    - email : " BW_EMAIL
    read -p "    - master password : " -s BW_PASSWORD
    echo

    bw config server "$BW_SERVER"
    export BW_SESSION=$(bw login "$BW_EMAIL" "$BW_PASSWORD" --raw 2>/dev/null)

    # Si déjà connecté, juste unlock
    if [ -z "$BW_SESSION" ]; then
      export BW_SESSION=$(bw unlock "$BW_PASSWORD" --raw 2>/dev/null)
    fi

    unset BW_PASSWORD
  fi

  if [ -z "$BW_SESSION" ]; then
    echo '    Bitwarden : échec de connexion'
    return 1
  fi

  # Récupère le contenu de la note sécurisée et source-le
  TMPVARS=$(mktemp)
  bw get notes "$BW_ITEM_NAME" --session "$BW_SESSION" > "$TMPVARS" 2>/dev/null
  if [ -s "$TMPVARS" ]; then
    source "$TMPVARS"
    rm -f "$TMPVARS"
    return 0
  fi
  rm -f "$TMPVARS"
  return 1
}

if [ -n "$2" ] && [ -f "$2" ]; then
  echo '\n👨‍🚀 Chargement des variables depuis l'"'"'argument...'
  source "$2"
elif _load_from_bitwarden 2>/dev/null; then
  echo '\n👨‍🚀 Chargement des variables depuis Bitwarden...'
elif [ -f "$ICLOUD_CONFIG" ]; then
  echo '\n👨‍🚀 Chargement des variables depuis iCloud...'
  source "$ICLOUD_CONFIG"
elif [ -f "$USB_CONFIG" ]; then
  echo '\n👨‍🚀 Chargement des variables depuis la clé USB...'
  source "$USB_CONFIG"
else
  echo '\n👨‍🚀 Fichier de variables introuvable, saisie manuelle :'

  DEFAULT_GIT_USER=$(git config --global user.name 2>/dev/null)
  DEFAULT_GIT_EMAIL=$(git config --global user.email 2>/dev/null)

  read -p "    - git username [${DEFAULT_GIT_USER}] : " GIT_USER
  GIT_USER="${GIT_USER:-$DEFAULT_GIT_USER}"

  read -p "    - git email [${DEFAULT_GIT_EMAIL}] : " GIT_EMAIL
  GIT_EMAIL="${GIT_EMAIL:-$DEFAULT_GIT_EMAIL}"

  if [ "$IS_PRO" = true ]; then
    DEFAULT_GIT_WORK_DIR=$(git config --global --list 2>/dev/null | grep 'includeif' | sed 's/.*gitdir://;s/\/.*/\//' | head -1)
    read -p "    - git email (work) : " GIT_WORK_EMAIL
    read -p "    - git work directory [${DEFAULT_GIT_WORK_DIR}] : " GIT_WORK_DIR
    GIT_WORK_DIR="${GIT_WORK_DIR:-$DEFAULT_GIT_WORK_DIR}"
  fi
fi

echo '\n👨‍🚀 For actions requiring sudo right, please provide sudo password now :'
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ─────────────────────────────────────────────────────────────────────────────
# HOMEBREW
# ─────────────────────────────────────────────────────────────────────────────

if test ! $(which brew)
then
  echo '\n👨‍🚀 Homebrew install'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo '\n👨‍🚀 Homebrew update'
brew update

echo '\n👨‍🚀 Installing Homebrew Taps'
brew tap buo/cask-upgrade
brew tap proxmark/proxmark3

# ─────────────────────────────────────────────────────────────────────────────
# COMMAND-LINE UTILS
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing command-line utils'
brew install git curl wget zsh cmake coreutils \
  bat eza fd fzf jq micro pv ripgrep trash watch \
  exiftool iperf lolcat mtr ncdu nmap nyancat speedtest-cli terminal-notifier thefuck wakeonlan \
  p7zip transmission-cli w3m

brew install font-meslo-lg-nerd-font font-fira-code-nerd-font font-hack-nerd-font font-sf-pro

echo '\n👨‍🚀 Installing oh-my-zsh in a new window'
osascript -e 'tell app "Terminal"
    do script "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
end tell'

# ─────────────────────────────────────────────────────────────────────────────
# GIT CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 git configuration'
git config --global core.editor "nano"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global pull.rebase false
git config --global push.autoSetupRemote true
git config --global credential.helper store

# gitignore global
if [ ! -f ~/.gitignore_global ]; then
  echo '*.DS_Store' > ~/.gitignore_global
fi
git config --global core.excludesfile '~/.gitignore_global'

# hooks template dir
mkdir -p ~/.git-templates/hooks
git config --global init.templateDir ~/.git-templates
git config --global core.hooksPath ~/.git-templates/hooks

# work gitconfig scoped par dossier (pro only)
if [ "$IS_PRO" = true ] && [ -n "$GIT_WORK_DIR" ] && [ -n "$GIT_WORK_EMAIL" ]; then
  mkdir -p ~/.config/git
  cat > ~/.config/git/work_gitconfig << EOF
[user]
  email = $GIT_WORK_EMAIL
EOF
  git config --global "includeIf.gitdir:${GIT_WORK_DIR}.path" ~/.config/git/work_gitconfig
fi

# ─────────────────────────────────────────────────────────────────────────────
# MAS HELPER
# ─────────────────────────────────────────────────────────────────────────────

brew install mas

function mas_install () {
  mas list | grep -i "$1" > /dev/null
  if [ "$?" == 0 ]; then
    echo "==> $1 is already installed"
  else
    echo "==> Installing $1..."
    mas search "$1" | { read app_ident app_name ; mas install $app_ident ; }
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# BROWSERS
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing web navigators'
brew install --cask arc firefox google-chrome opera-neon

# ─────────────────────────────────────────────────────────────────────────────
# SOCIAL & COMMUNICATION
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing social & communication apps'
SOCIAL_CASKS="discord slack telegram whatsapp"
[ "$IS_PRO" = true ] && SOCIAL_CASKS="$SOCIAL_CASKS mattermost microsoft-teams"
brew install --cask $SOCIAL_CASKS

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing utilities apps'
brew install --cask aerial antigravity balenaetcher blackhole-2ch cyberduck daisydisk \
  developerexcuses eul exodus handbrake hugin lunar notion raspberry-pi-imager rectangle \
  stremio wireshark
mas_install 'Amphetamine'
mas_install 'Encrypto'
mas_install 'GoPro Player'
mas_install 'Home Assistant'
mas_install 'NTFS Disk by Omi'
mas_install 'Spark'
mas_install 'The Unarchiver'

# ─────────────────────────────────────────────────────────────────────────────
# MUSIC & MEDIA
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing music apps'
brew install --cask lastfm spotify

echo '\n👨‍🚀 Installing video apps'
brew install --cask iina vlc

# ─────────────────────────────────────────────────────────────────────────────
# DEVELOPMENT
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing development apps'

# Languages & runtimes
brew install go rust imagemagick node rbenv ruby-build python@3.13 uv asdf
rbenv install 3.3.0
rbenv global 3.3.0

# asdf plugins — mettre à jour les versions selon besoin
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin add nodejs
asdf install erlang 28.3
asdf install elixir 1.19.4
asdf install nodejs 24.10.0
asdf global erlang 28.3
asdf global elixir 1.19.4
asdf global nodejs 24.10.0

# Cloud & infra
INFRA_FORMULAS="awscli terraform"
INFRA_CASKS=""
[ "$IS_PRO" = true ] && INFRA_FORMULAS="$INFRA_FORMULAS aws-cdk serverless"
[ "$IS_PRO" = true ] && INFRA_CASKS="session-manager-plugin chef-workstation"
brew install $INFRA_FORMULAS
[ -n "$INFRA_CASKS" ] && brew install --cask $INFRA_CASKS

# Mobile dev
brew install --cask android-studio android-file-transfer android-platform-tools

# Databases
brew install mysql postgresql@14
brew install --cask another-redis-desktop-manager dbeaver-community

# Editors & IDEs
EDITOR_CASKS="sublime-text visual-studio-code visual-studio-code-insiders warp"
[ "$IS_PRO" = true ] && EDITOR_CASKS="$EDITOR_CASKS cursor"
brew install --cask $EDITOR_CASKS

# API clients
API_CASKS="postman"
[ "$IS_PRO" = true ] && API_CASKS="$API_CASKS bruno insomnia"
brew install --cask $API_CASKS

# Docker
brew install --cask docker docker-desktop

# Other dev tools
brew install fastlane
brew install --cask arduino beyond-compare figma intellij-idea-ce playcover-community

# App Store dev
mas_install 'Xcode'
mas_install 'DevCleaner'

echo '\n👨‍🚀 Installing npm global packages'
npm install -g brb tldr wscat artillery @github/copilot

# ─────────────────────────────────────────────────────────────────────────────
# SECURITY
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing security apps'
SECURITY_CASKS="authy bitwarden keybase protonvpn private-internet-access tunnelblick"
[ "$IS_PRO" = true ] && SECURITY_CASKS="$SECURITY_CASKS mitmproxy"
brew install proxmark3
[ "$IS_PRO" = true ] && brew install amass subfinder httpx ffuf
brew install --cask $SECURITY_CASKS
mas_install 'Encrypto'

# ─────────────────────────────────────────────────────────────────────────────
# OFFICE
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing office apps'
OFFICE_CASKS="macdown"
[ "$IS_PRO" = true ] && OFFICE_CASKS="$OFFICE_CASKS microsoft-office"
brew install --cask $OFFICE_CASKS
mas_install 'Keynote'
mas_install 'Numbers'
mas_install 'Pages'

# ─────────────────────────────────────────────────────────────────────────────
# GAMES
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing games'
brew install --cask league-of-legends minecraft openemu steam

# ─────────────────────────────────────────────────────────────────────────────
# AI TOOLS
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Installing AI tools'
AI_CASKS="chatgpt claude claude-code"
[ "$IS_PRO" = true ] && AI_CASKS="$AI_CASKS lm-studio"
brew install --cask $AI_CASKS

# ─────────────────────────────────────────────────────────────────────────────
# CLEANUP
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Post install cleanup'
brew cleanup

# ─────────────────────────────────────────────────────────────────────────────
# macOS PREFERENCES
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Setting up macOS preferences'

# daily updates
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled true
defaults write com.apple.SoftwareUpdate ScheduleFrequency 1
defaults write com.apple.SoftwareUpdate AutomaticDownload true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall true
defaults write com.apple.commerce AutoUpdate true

# don't write DS_store files on network and usb devices
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
defaults write com.apple.desktopservices DSDontWriteUSBStores true

# finder
defaults write com.apple.finder ShowStatusBar false
defaults write com.apple.finder FXPreferredViewStyle 'clmv'
defaults write com.apple.finder NewWindowTargetPath "'file://$HOME'"
defaults write com.apple.finder FXEnableExtensionChangeWarning false
defaults write com.apple.finder _FXSortFoldersFirst true
defaults write com.apple.finder FXDefaultSearchScope "SCcf"

# contacts sorting
defaults write com.apple.AddressBook ABNameDisplay false
defaults write com.apple.AddressBook ABNameSortingFormat 'sortingFirstName sortingLastName'

# desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 29" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 32" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:textSize 32" ~/Library/Preferences/com.apple.finder.plist

# safari
defaults write com.apple.Safari SendDoNotTrackHTTPHeader false
defaults write com.apple.Safari CanPromptForPushNotifications false

# dock
defaults write com.apple.dock magnification true
defaults write com.apple.dock orientation 'Left'
defaults write com.apple.dock autohide true
defaults write com.apple.dock tilesize 30
defaults write com.apple.dock largesize 67

# screensaver
defaults -currentHost write com.apple.screensaver askForPassword true
defaults -currentHost write com.apple.screensaver askForPasswordDelay 0
defaults -currentHost write com.apple.screensaver idleTime 300

# screenshots
defaults write com.apple.screencapture location "${HOME}/Desktop"
defaults write com.apple.screencapture type "png"

# simulators
sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app" "/Applications/Simulator.app"
sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/Simulator (Watch).app" "/Applications/Simulator (Watch).app"

# hot corners
defaults write com.apple.dock wvous-tl-corner 2
defaults write com.apple.dock wvous-tl-modifier 0
defaults write com.apple.dock wvous-tr-corner 3
defaults write com.apple.dock wvous-tr-modifier 0
defaults write com.apple.dock wvous-bl-corner 7
defaults write com.apple.dock wvous-bl-modifier 0
defaults write com.apple.dock wvous-br-corner 4
defaults write com.apple.dock wvous-br-modifier 0

# timemachine
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup true

# disable photo pop-up
defaults -currentHost write com.apple.ImageCapture disableHotPlug true

# ignore quarantine
defaults write com.apple.LaunchServices LSQuarantine false

# trackpad
defaults write NSGlobalDomain com.apple.swipescrolldirection false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior true

# textedit : txt
defaults write com.apple.TextEdit RichText -int 0

# ─────────────────────────────────────────────────────────────────────────────
# APP SETTINGS
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Setting up applications preferences'

# zshrc
curl -o ~/.zshrc https://raw.githubusercontent.com/Kamasoutra/macOS-config/master/app_settings/zsh/zshrc

# oh-my-zsh theme
curl -o ~/.oh-my-zsh/themes/kama.zsh-theme https://raw.githubusercontent.com/Kamasoutra/macOS-config/master/app_settings/oh-my-zsh/kama.zsh-theme

# ─────────────────────────────────────────────────────────────────────────────
# macOS UPDATES
# ─────────────────────────────────────────────────────────────────────────────

echo '\n👨‍🚀 Checking for macOS updates'
softwareupdate -ia

echo '\n👨‍🚀 All set up, just reboot !'
