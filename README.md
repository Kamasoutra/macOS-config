# macOS-config

Unified setup script for a new Mac — supports both personal and pro configurations.

## Usage

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Kamasoutra/macOS-config/master/config.sh)"
```

The script will ask whether you're setting up a **perso** or **pro** machine, then install and configure everything accordingly.

### Arguments (optional)

```sh
# Specify machine type directly
./config.sh pro
./config.sh perso

# Specify machine type + path to a variables file
./config.sh pro /path/to/macOS-config-variables
```

## Variables file

The script looks for your variables in this order:

1. **Argument** — path passed as second argument
2. **Bitwarden** — secure note named `macOS-config-variables` in your vault
3. **iCloud Drive** — `~/Library/Mobile Documents/com~apple~CloudDocs/macOS-config-variables`
4. **USB** — `/Volumes/Kama-encrypted/#pro/` or `#Kama/`
5. **Interactive prompt** — falls back to manual input (reads existing git config as defaults)

See `macOS-config-variables.example` for the expected format.

## What gets installed

| Category | Notable tools |
|---|---|
| CLI | git, bat, eza, fzf, ripgrep, jq, micro, mtr, trash… |
| Browsers | Arc, Firefox, Chrome |
| Dev | VS Code, Warp, Docker, Android Studio, Postgres, MySQL… |
| Cloud (pro) | awscli, terraform, aws-cdk, serverless |
| Security | Bitwarden, ProtonVPN, proxmark3, authy… |
| Security recon (pro) | amass, subfinder, httpx, ffuf, mitmproxy |
| AI | Claude, ChatGPT, LM Studio (pro) |
| Games | Steam, League of Legends, Minecraft, OpenEmu |

## Credits

Based on the work of:
- nicolinuxfr: https://github.com/nicolinuxfr/macOS-post-installation
- kevinSuttle: https://github.com/kevinSuttle/macOS-Defaults
- mathiasbynens: https://github.com/mathiasbynens/dotfiles
