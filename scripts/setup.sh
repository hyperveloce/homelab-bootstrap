#!/bin/bash

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

command_exists () {
    command -v $1 >/dev/null 2>&1;
}
## include below into script
# # System setup
# sudo timedatectl set-timezone Australia/Melbourne

# # user setup
# sudo adduser kanasu
# sudo usermod -aG sudo kanasu

# # firewall setup
# sudo apt install ufw
# sudo ufw default deny incoming
# sudo ufw default allow outgoing
# sudo ufw allow 22/tcp  # or the port you set for SSH
# sudo ufw enable

# # brute force protection
# sudo apt install fail2ban
# sudo systemctl enable fail2ban

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt yum dnf pacman zypper'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi


    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [[ ! -w ${GITPATH} ]]; then
        echo -e "${RED}Can't write to ${GITPATH}${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug}; then
            SUGROUP=${sug}
            echo -e "Super user group ${SUGROUP}"
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!"
        exit 1
    fi

}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='autojump bash bash-completion tar neovim bat'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [[ $PACKAGER == "pacman" ]]; then
        if ! command_exists yay; then
            echo "Installing yay..."
            sudo ${PACKAGER} --noconfirm -S base-devel
            $(cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git && cd yay-git && makepkg --noconfirm -si)
        else
            echo "Command yay already installed"
        fi
    	yay --noconfirm -S ${DEPENDENCIES}
    else
    	sudo ${PACKAGER} install -yq ${DEPENDENCIES}
    fi
}

installStarship(){
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi

    if ! curl -sS https://starship.rs/install.sh|sh;then
        echo -e "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
}

create_fastfetch_config() {
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    CONFIG_DIR="$USER_HOME/.config/fastfetch"
    CONFIG_FILE="$CONFIG_DIR/config.jsonc"

    mkdir -p "$CONFIG_DIR"
    [ -e "$CONFIG_FILE" ] && rm -f "$CONFIG_FILE"

    if ! ln -svf "$GITPATH/fastfetch/config.jsonc" "$CONFIG_FILE"; then
        print_colored "$RED" "Failed to create symbolic link for fastfetch config"
        exit 1
    fi
}

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
    ## Check if a bashrc file is already there.
    OLD_BASHRC="${USER_HOME}/.bashrc"
    if [[ -e ${OLD_BASHRC} ]]; then
        echo -e "${YELLOW}Moving old bash config file to ${USER_HOME}/.bashrc.bak${RC}"
        if ! mv ${OLD_BASHRC} ${USER_HOME}/.bashrc.bak; then
            echo -e "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    echo -e "${YELLOW}Linking new bash config file...${RC}"
    ## Make symbolic link.
    ln -svf ${GITPATH}/.bashrc ${USER_HOME}/.bashrc
    ln -svf ${GITPATH}/${HOSTNAME}-starship.toml ${USER_HOME}/.config/starship.toml
    mkdir ${USER_HOME}/.config/kitty
    ln -svf ${GITPATH}/kitty/current-theme.conf ${USER_HOME}/.config/kitty/current-theme.conf
    ln -svf ${GITPATH}/kitty/kitty.conf ${USER_HOME}/.config/kitty/kitty.conf
    ln -svf ${GITPATH}/kitty/theme.conf ${USER_HOME}/.config/kitty/theme.conf
    mkdir ${USER_HOME}/.config/zed
    ln -svf ${GITPATH}/zed/settings.conf ${USER_HOME}/.config/zed/settings.conf
}

checkEnv
installDepend
installStarship
if linkConfig; then
    echo -e "${GREEN}Done!\nrestart your shell to see the changes.${RC}"
else
    echo -e "${RED}Something went wrong!${RC}"
fi
