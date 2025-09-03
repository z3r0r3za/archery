#!/usr/bin/env bash

# bumblebee-status current requirements:
# iw, gnome-system-monitor, pacman-contrib, python-psutil, pamixer, python-netifaces, yay

exec > >(tee $HOME/Scripts/i3_setup.log) 2>&1

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

NOTE: still in progress and testing.

Setup starts or stops when key is pressed (1 or q):

  [1] Install everything 
  [2] Install everything - vmware
  [3] Install everything - nvidia
  [q] Quit without installing

EOF

init() {
    # Possible themes: 
    # https://github.com/vinceliuice/Vimix-gtk-themes
    # https://github.com/vinceliuice/Matcha-gtk-theme
    # https://github.com/vinceliuice/Yosemite-gtk-theme
    mkdir -p "$UHOME/Scripts"
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
        "iw" \
        "go" \
        "zsh" \
        "guake" \
        "helix" \
        "fish" \
        "tmux" \
        "gimp" \
        "clamav" \
        "plocate" \
        "obsidian" \
        "xmlstarlet" \
        "xarchiver" \
        "alacritty" \
        "rssguard" \
        "i3blocks" \
        "pamixer" \
        "rssguard" \
        "chromium" \
        "thunderbird" \
        "galculator" \
        "sublime-text" \
        "ttf-hack" \
        "noto-fonts" \
        "ttf-roboto" \
        "ttf-dejavu" \
        "terminus-font" \
        "ttf-mplus-nerd" \
        "ttf-terminus-nerd" \
        "ttf-bitstream-vera" \
        "zsh-lovers" \
        "zsh-completions" \
        "zsh-autosuggestions" \
        "zsh-syntax-highlighting" \
        "zsh-history-substring-search" \
        "xorg-xdpyinfo" \
        "python-netifaces" \
        "gnome-system-monitor" \
        "awesome-terminal-fonts" \
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
    # sudo pacman -Sy && sudo pacman -S --noconfirm "${to_install[@]}" || true
    if [ ${#to_install[@]} -gt 0 ]; then
        sudo pacman -Sy && sudo pacman -S "${to_install[@]}" || true
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
    
    # i3, dunst, conky configs and scripts.
    sudo cp "$UHOME/Scripts/archery/files/usr_bin/i3-alt-tab.py" /usr/bin
    sudo cp "$UHOME/Scripts/archery/files/etc/i3status.conf" /etc
    sudo cp "$UHOME/Scripts/archery/files/etc/i3blocks.conf" /etc
    sudo cp "$UHOME/Scripts/archery/files/etc/dunst/dunstrc" /etc/dunst
    sudo cp "$UHOME/Scripts/archery/files/usr_bin/start_conky_maia" /usr/bin
    
    # i3blocks configs
    I3BLOCKS="$UHOME/Scripts/archery/files/home_user_config"
    I3BLOCKSDEST="$UHOME/.config/"
    unzip -q $I3BLOCKS/i3blocks.zip -d $I3BLOCKSDEST || true

    # Create symlinks for i3 utilities.
    ln -s /usr/bin/i3-alt-tab.py "$UHOME/.config/i3/i3-alt-tab.py"
    ln -s /etc/i3status.conf "$UHOME/.config/i3/i3status.conf"
    
    # Conky config.
    sudo cp "$UHOME/Scripts/archery/files/usr_share/conky/conky_maia" /usr/share/conky
    sudo cp "$UHOME/Scripts/archery/files/usr_share/conky/conky1.10_shortcuts_maia" /usr/share/conky

    # bash and zsh configs
    if [[ -f "$UHOME/.zshrc" ]]; then
        mv "$UHOME/.zshrc" "$UHOME/.zshrc_BACKUP"
        cp "$UHOME/Scripts/archery/files/home_user/zshrc" "$UHOME/.zshrc"
    fi
    if [[ -f "$UHOME/.bashrc" ]]; then
        mv "$UHOME/.bashrc" "$UHOME/.bashrc_BACKUP"
        cp "$UHOME/Scripts/archery/files/home_user/bashrc" "$UHOME/.bashrc"
    fi
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
    unzip -q $UHOME/Scripts/archery/files/alacritty.zip -d $UHOME/Scripts/archery/files $DESTINATION || true
    cp "$UHOME/Scripts/archery/files/alacritty/alacritty.toml" "$UHOME/.config/alacritty"
    cp "$UHOME/Scripts/archery/files/alacritty/dracula.toml" "$UHOME/.config/alacritty/themes"
    cp "$UHOME/Scripts/archery/files/alacritty/terafox.toml" "$UHOME/.config/alacritty/themes"
    cp "$UHOME/Scripts/archery/files/alacritty/zatonga.toml" "$UHOME/.config/alacritty/themes"
}

install_bb() {
    cd /usr/share
    sudo git clone https://github.com/tobi-wan-kenobi/bumblebee-status
    cd "$UHOME/Scripts/archery"
    local BBTHEME="$UHOME/Scripts/archery/files/home_user_config/i3"
    echo "[+] Set up bumblebee-status theme."
    sudo cp "$BBTHEME/solarized-powerlined.json" /usr/share/bumblebee-status/themes/solarized-powerlined.json
    local CUSTOMMOD="$UHOME/Scripts/archery/files/usr_share/bumblebee_status/modules/contrib/"
    local CONTRIB="/usr/share/bumblebee-status/bumblebee_status/modules/contrib"
    sudo mv "$CONTRIB/arch-update.py" "$CONTRIB/arch-update.py_BACKUP"
    sudo mv "$CONTRIB/pamixer.py" "$CONTRIB/pamixer.py_BACKUP"
    sudo cp "$CUSTOMMOD/arch-update.py" $CONTRIB
    sudo cp "$CUSTOMMOD/pamixer.py" $CONTRIB
    sudo ln -s /usr/share/bumblebee-status/bumblebee-status /usr/bin/bumblebee-status
}

# Install nvm.
install_nvm() {
    echo "[+] Install nvm for $CURUSER."
    cd "$UHOME"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_yay() {
    cd "$UHOME/Scripts"
    YAYURLS=("https://aur.archlinux.org/yay.git" "https://github.com/archlinux/aur.git")
    if [ ! -d "yay" ]; then
        if git ls-remote "${YAYURLS[0]}" > /dev/null; then
            echo "Trying ${YAYURLS[0]} for this download."
            git clone "${YAYURLS[0]}"
        elif git ls-remote "${YAYURLS[1]}" yay > /dev/null; then
            echo "Failed to reach AUR ${YAYURLS[0]}."
            echo "Trying github mirror ${YAYURLS[1]}..."
            git clone --branch yay --single-branch ${YAYURLS[1]} yay
        else
            echo "Could not download yay."
        fi
    fi
   
    if [ -d "yay" ]; then
        cd yay
        makepkg -si
    else
        echo "Could not install yay."
    fi

    cd "$UHOME/Scripts"
}

bg_fa() {
    # Temp setup for a background and fontawesome.
    cd "$UHOME/Scripts"
    wget -q https://notes.z3r0r3z.com/bg_fa.tar.gz --directory "$UHOME/Scripts" || true
    tar -C "$UHOME/Scripts" -xzf /bg_fa.tar.gz
    sudo mkdir -p /usr/share/backgrounds
    sudo cp "$UHOME/Scripts/bg_fa/arch_ascii_1920x1080.jpg" /usr/share/backgrounds
    sudo cp "$UHOME/Scripts/bg_fa/arch_ascii_2560_1440.jpg" /usr/share/backgrounds
    cp "$UHOME/Scripts/bg_fa/fontawesome.ttf" "$UHOME/.local/share/fonts"
}

set_gtk_theme() {
    #sudo echo 'GTK_THEME="adw-gtk3-dark"' >> /etc/environment
    #sudo sh -c 'echo "GTK_THEME=\"adw-gtk3-dark\"" >> /etc/environment'
    echo 'GTK_THEME="adw-gtk3-dark"' | sudo tee -a /etc/environment
}

install_betterlock() {
    # yay -S i3lock-color - it's installed as dependency.
    yay -S betterlockscreen

    betterlockscreen -u /usr/share/backgrounds/arch_ascii_1920x1080.jpg
}

install_xautolock() {
    cd "$UHOME/Scripts"
    if git ls-remote https://aur.archlinux.org/xautolock.git > /dev/null; then
        git clone https://aur.archlinux.org/xautolock.git
    fi
    if [ -d "xautolock" ]; then
        cd xautolock
        makepkg -si
    else   
        echo "Could not install xautolock."
    fi
    cd "$UHOME/Scripts"
}

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

install_go() {
    # https://go.dev/doc/install
    # https://go.dev/dl/go1.25.0.linux-amd64.tar.gz
    cd "$UHOME/Scripts"
    GOVERSIONURL="https://go.dev/VERSION?m=text"
    GOVERSION=$(curl -s "$GOVERSIONURL" | head -n 1)
    GOURL="https://go.dev/dl/$GOVERSION.linux-amd64.tar.gz"
    wget $GOURL
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$GOVERSION.linux-amd64.tar.gz"
}

start_fish() {
    chsh -s /usr/bin/fish
}

nvidia() {
    pacman -S nvidia nvidia-utils nvidia-settings
}

# Don't need if installed already.
open_vm_tools() {
    sudo pacman -Ss open-vm-tools
    sudo systemctl enable vmtoolsd.service
    sudo systemctl enable vmware-vmblock-fuse.service
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
    install_yay
    bg_fa
    #set_gtk_theme
    install_betterlock
    install_xautolock
    install_rust
    #install_go
    start_fish
}

run_everything_vmware() {
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
    install_yay
    bg_fa
    #set_gtk_theme
    install_betterlock
    install_xautolock
    install_rust
    #install_go
    start_fish
    open_vm_tools
}

run_everything_nvidia() {
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
    install_yay
    bg_fa
    #set_gtk_theme
    install_betterlock
    install_xautolock
    install_rust
    #install_go
    start_fish    
    nvidia
}

while true; do
    read -n1 -p "Enter option [1] or press q to exit: " choice
    case "$choice" in
        1) run_everything; break ;;
        2) run_everything_vmware; break ;;
        2) run_everything_nvidia; break ;;
        [Qq]) echo -e "\nExiting..."; exit 0 ;;
        *) echo -e "Invalid input. Please enter 1 or q to exit.\n" ;;
    esac
done
