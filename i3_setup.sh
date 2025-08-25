#!/usr/bin/env bash


# cat /home/kali/Downloads/afterPMi3/afterPMi3.log to view logs.
exec > >(tee $HOME/Scripts/archery/archery.log) 2>&1

CURUSER="$USER"
UHOME="$HOME"

cat <<EOF

###########################################################################
##                        Arch Linux Setup                               ##
###########################################################################

This script continues the set up of Arch Linux after initial installation.
It installs more apps, fonts, i3 and other configs, shells, etc.
This file should be run from /home/$CURUSER/Scripts/archery/
You will need to enter your sudo password.

Setup starts or stops when key is pressed (1 or q):

  [1] Install everything now
  [q] Quit without installing

EOF

init() {
    #mkdir -p "/home/$CURUSER/Scripts"
    echo "Enter the sudo password for $CURUSER..."
    mkdir -p "$UHOME/tmux_buffers"
    mkdir -p "$UHOME/tmux_logs"
    sudo mkdir -p /usr/share/conky
}

# https://www.sublimetext.com/docs/linux_repositories.html
setup_subl() {
    echo "[+] Setting up Sublime Text for $CURUSER."
    curl -O https://download.sublimetext.com/sublimehq-pub.gpg && sudo pacman-key --add sublimehq-pub.gpg && sudo pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg
    echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" | sudo tee -a /etc/pacman.conf
}

# Check and install packages.
pacman() {
    echo
    echo "[+] Checking and installing packages for $CURUSER."
    local packages=(
        "guake" \
        "helix" \
        "fish" \
        "tmux" \
        "xsel" \
        "wget" \
        "obsidian" \
        "xmlstarlet" \
        "terminator" \
        "alacritty" \
        "rssguard" \
        "pamixer" \
        "rssguard" \
        "chromium" \
        "thunderbird" \
        "galculator" \
        "sublime-text" \
        "gnome-system-monitor" \
        "firefox-developer-edition"
    )
    # Array to hold packages that are not installed
    local -a to_install=()
    
    # Check which packages might exist.
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    # Install only the missing packages.
    if [ ${#to_install[@]} -gt 0 ]; then
        sudo pacman -Sy && sudo pacman -S --noconfirm "${to_install[@]}" || true
    else
        echo "[-] All required packages are installed."
    fi
}

# Createp i3, other configs and directories.
i3_config() {
    echo "[+] Setting up i3 and some other configs for $CURUSER."
    #mkdir -p "/home/$CURUSER/.config/i3"

    # Create a backups of the default files.
    mv "$UHOME/.config/i3/config" "$UHOME/.config/i3/config_BACKUP"
    sudo mv "/etc/i3status.conf" "/etc/i3status.conf_BACKUP"
    
    # Copy i3 new config and key commands files for kali user.
    cp "$UHOME/Scripts/archery/files/home_user_config/i3/config" "$UHOME/.config/i3/"
    cp "$UHOME/Scripts/archery/files/home_user_config/i3/i3_keys.txt" "$UHOME/.config/i3/i3_keys.txt"
    
    sudo cp "$UHOME/Scripts/archery/files/usr_bin/i3-alt-tab.py" /usr/bin
    sudo cp "$UHOME/Scripts/archery/files/etc/i3status.conf" /etc
    sudo cp "$UHOME/Scripts/archery/files/etc/i3blocks.conf" /etc
    sudo cp "$UHOME/Scripts/archery/files/etc/dunst/dunstrc" /etc/dunst
    sudo cp "$UHOME/Scripts/archery/files/usr_bin/start_conky_maia" /usr/bin
    
    # Create symlinks for i3 utilities.
    ln -s /usr/bin/i3-alt-tab.py "$UHOME/.config/i3/i3-alt-tab.py"
    ln -s /etc/i3status.conf "$UHOME/.config/i3/i3status.conf"
    
    sudo cp "$UHOME/Scripts/archery/files/usr_share/conky/conky_maia" /usr/share/conky
    sudo cp "$UHOME/Scripts/archery/files/usr_share/conky/conky1.10_shortcuts_maia" /usr/share/conky
}

install_fonts() {
    echo
    echo -e "[+] Downloading and installing Powerline fonts, Nerd-fonts for $CURUSER."
    cd "$UHOME/Downloads"
    mkdir "$UHOME/Downloads/extra_fonts"
    local URL1="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
    local URL2="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Monoid.zip"
    local URL3="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hack.zip"
    local TARGET="$UHOME/.local/share/fonts"
    local DESTINATION="$UHOME/Downloads/extra_fonts"

    # Download all the zip files in the background.
    wget -q "$URL1" --directory $DESTINATION || true
    wget -q "$URL2" --directory $DESTINATION || true
    wget -q "$URL3" --directory $DESTINATION || true
    
    if [[ ! -f "$DESTINATION/FiraCode.zip" && ! -f "$DESTINATION/Monoid.zip" && ! -f "$DESTINATION/Hack.zip" ]]; then
        echo "Failed to download ZIP files. Please check the URLs or network connection."
        exit 1
    fi

    # Unzip the files to target.
    unzip -q $DESTINATION/FiraCode.zip -d $DESTINATION/FiraCode || true
    unzip -q $DESTINATION/Monoid.zip -d $DESTINATION/Monoid || true
    unzip -q $DESTINATION/Hack.zip -d $DESTINATION/Hack || true

    # Copy fonts to target directory.
    FONT_SOURCED=("$DESTINATION/FiraCode" "$DESTINATION/Monoid" "$DESTINATION/Hack")

    # Font target directory.
    FONT_DESTD="$UHOME/.local/share/fonts"
    if [ ! -d "$FONT_DESTD" ]; then
        mkdir $FONT_DESTD
    fi
    
    # Excluded filenames from font directory
    EXCLUDED_FILES=("LICENSE" "README.md")

    # Loop through each source directory
    for dir in "${FONT_SOURCED[@]}"; do
        find "$dir" -type f \( \
            ! -name "${EXCLUDED_FILES[0]}" -a \
            ! -name "${EXCLUDED_FILES[1]}" \
        \) -exec cp {} "$TARGET" \;
    done

    echo "[+] Installing Powerline fonts for $CURUSER."
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    # Reload font cache.
    fc-cache -f "$UHOME/.local/share/fonts"
}

# Install and set up oh-my-tmux for user.
install_ohmytmux() {
    echo "[+] Installing Oh-my-tmux"
    cd "$UHOME"
    git clone --single-branch https://github.com/gpakosz/.tmux.git
    ln -s -f .tmux/.tmux.conf
    # Commenting this line because the config already exists.
    #cp .tmux/.tmux.conf.local .
    cp "$UHOME/Scripts/archery/files/home_user/tmux.conf.txt" "$UHOME/.tmux.conf.local"
}

# Set up fish config for kali user.
fish_config() {
    echo "[+] Set up fish config for $CURUSER."
    cd "/home/$CURUSER/Scripts/archery/"
    local FISHDIR="/home/$CURUSER/.config/fish"
    local CONFDIR="/home/$CURUSER/.config"
    if [ -d "$FISHDIR" ]; then
        rm -rf $FISHDIR
        unzip -q files/fish.zip -d $CONFDIR || true
    fi
    if [ ! -d "$FISHDIR" ]; then
        unzip -q files/fish.zip -d $CONFDIR || true
    fi
}

alacritty_theme() {
    echo "[+] Set up alacritty themes."
    cd "$UHOME/Scripts/archery"
    mkdir "$UHOME/.config/alacritty"
    mkdir "$UHOME/.config/alacritty/themes"
    unzip -q files/alacritty.zip || true
    cp "$UHOME/Scripts/archery/files/alacritty/alacritty.toml" "$UHOME/.config/alacritty"
    cp "$UHOME/Scripts/archery/files/alacritty/dracula.toml" "$UHOME/.config/alacritty/themes"
    cp "$UHOME/Scripts/archery/files/alacritty/terafox.toml" "$UHOME/.config/alacritty/themes"
    cp "$UHOME/Scripts/archery/files/alacritty/zatonga.toml" "$UHOME/.config/alacritty/themes"
}

install_bb() {
    cd "$UHOME/Scripts/archery"
    local BBTHEME="$UHOME/Scripts/archeryfiles/home_user_config/i3/"
    git clone https://github.com/tobi-wan-kenobi/bumblebee-status
    sudo mv bumblebee-status /usr/share
    echo "[+] Set up bumblebee-status theme."
    sudo cp "$BBTHEME/solarpower.json" /usr/share/bumblebee-status/themes/solarized-powerlined.json
    
    local CUSTOMMOD="$UHOME/Scripts/archery/files/usr_share/bumblebee-status/modules/contrib/"
    local CONTRIB="/usr/share/bumblebee-status/bumblebee-status/modules/contrib"
    sudo mv "$CONTRIB/arch-update.py" "$CONTRIB/arch-update.py_BACKUP"
    sudo mv "$CONTRIB/pamixer.py" "$CONTRIB/pamixer.py_BACKUP"
    sudo cp "$CUSTOMMOD/arch-update.py" $CONTRIB
    sudo cp "$CUSTOMMOD/pamixer.py" $CONTRIB
}

# Install nvm.
install_nvm() {
    echo "[+] Install nvm for $CURUSER."
    cd "$UHOME"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

run_everything() {
    init
    setup_subl
    pacman
    i3_config
    install_fonts
    install_ohmytmux
    fish_config
    alacritty_theme
    install_bb
    install_nvm
}

while true; do
    read -n1 -p "Enter option [1] or press q to exit: " choice
    case "$choice" in
        1) run_everything; break ;;
        [Qq]) echo -e "\nExiting..."; exit 0 ;;
        *) echo -e "Invalid input. Please enter 1 or q to exit.\n" ;;
    esac
done
