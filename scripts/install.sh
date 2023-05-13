#!/bin/bash

# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Bash is required
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# Check OS.
OS="$(uname)"
if [[ "${OS}" != "Linux" ]]; then
  abort "This install script only supports Linux."
fi

# Elevate permissions
if [ $(id -u) != 0 ]; then
   sudo "$0" "$@"
   exit
fi

refresh_pkg_manager() {
    echo "Refreshing packages cache."
    $PKG_MANAGER update >/dev/null
}

get_install_command() {
    if command -v apt-get >/dev/null; then
        echo "apt-get"
    elif command -v yum >/dev/null; then
        echo "yum"
    else
        abort "This install script only supports apt or yum package managers."
    fi
}

install_kurtosis() {
    echo "Installing Kurtosis"
    if [[ "${PKG_MANAGER}" == "apt" ]]; then
        echo "deb [trusted=yes] https://apt.fury.io/kurtosis-tech/ /" | tee /etc/apt/sources.list.d/kurtosis.list
    elif [[ "${PKG_MANAGER}" == "yum" ]]; then
        echo '[kurtosis]
        name=Kurtosis
        baseurl=https://yum.fury.io/kurtosis-tech/
        enabled=1
        gpgcheck=0' | tee /etc/yum.repos.d/kurtosis.repo
    fi
    $PKG_MANAGER install kurtosis-cli
}

install_bash_completion() {
    echo "Installing bash completion"
    $PKG_MANAGER install bash-completion
    echo "Add the following line to your shell profile:"
    echo 'source <(kurtosis completion bash)'
}

install_docker () {
    echo "Installing Docker"
    if ! curl -fsSL get.docker.com -o get-docker.sh >/dev/null; then
        abort "Could not download the Docker install script."
    fi
    chmod +x get-docker.sh
    if ! ./get-docker.sh >/dev/null; then
        rm -f get-docker.sh
        abort "Could not install Docker."
    fi
    rm -f get-docker.sh
}

install_curl () {
    echo "Installing curl."
    if ! $PKG_MANAGER install curl >/dev/null; then
        abort "Could not install curl."
    fi
}

PKG_MANAGER="$(get_install_command)"
refresh_pkg_manager

if ! command -v curl >/dev/null; then
    install_curl
fi

if ! command -v docker >/dev/null; then
    install_docker
fi

if ! command -v kurtosis >/dev/null; then
    install_kurtosis
fi

if ! type _init_completion >/dev/null; then
    install_bash_completion
fi
