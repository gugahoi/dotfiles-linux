#!/usr/bin/env bash

set -e
set -o pipefail

# TODO: need to create a rule with powertop --auto-tune

base() {
	apt update
	apt -y upgrade
	apt install -y --no-install-recommends \
		alsa-utils \
		arandr \
		cmatrix \
		compton \
		curl \
		feh \
		git \
		help2man \
		i3 \
		icdiff \
		jq \
		make \
		neofetch \
		neovim \
		network-manager \
		openvpn \
		powertop \
		rofi \
		s3cmd \
		scrot \
		shellcheck \
		terminator \
		tig \
		tlp \
		tlp-rdw \
		ttf-ancient-fonts \
		wicd \
		wicd-curses

	apt autoremove
	apt autoclean
	apt clean
}

# installs docker master
install_docker() {
	groupadd docker
	gpasswd -a $USER docker

	apt-get install -y \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    software-properties-common	

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

	# zesty because artful (17.10) is no good for now
	add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   zesty \
	   stable"

	apt update
	apt install -y docker-ce
	
	apt autoremove
	apt autoclean
	apt clean
}

install_docker_compose() {
	local binary=/usr/local/bin/docker-compose
	local version=1.18.0

	curl -L https://github.com/docker/compose/releases/download/${version}/docker-compose-`uname -s`-`uname -m` -o ${binary}
	chmod +x ${binary}
}

# install go from gophers repo
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
		curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
		local user="$USER"
		# rebuild stdlib for faster builds
		sudo chown -R "${user}" /usr/local/go/pkg
		CGO_ENABLED=0 $GO_SRC/bin/go install -a -installsuffix cgo std
		ln -s $GO_SRC/bin/go /usr/local/bin/go
	)
}	

install_spotify() {
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410
	echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
	apt update
	apt install -y spotify-client
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	(
		curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
		chmod +x /usr/local/bin/speedtest
	)

	# install lolcat
	(
		curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
		chmod +x /usr/local/bin/lolcat
	)

	# install light (need help2man which is installed in base)
	( 
		git clone https://github.com/haikarainen/light.git /opt/light/
		cd /opt/light
		make && make install
	)
}

install_kubectl() {
	KUBERNETES_VERSION=$(curl -sSL https://storage.googleapis.com/kubernetes-release/release/stable.txt)
	curl -sSL "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl" > /usr/local/bin/kubectl
	chmod +x /usr/local/bin/kubectl
}

install_vscode() { 
	local tmp_file=$(mktemp)
	curl https://go.microsoft.com/fwlink/?LinkID=760868 -L --output $tmp_file
 	dpkg -i $tmp_file
	rm $tmp_file
}

# symlink all the things
symlinks() {
	ln -s ~/.dotfiles/.wallpaper ~/.wallpaper
}

die() { echo "$@" && exit 1}
check_is_sudo() { [ "$EUID" -ne 0 ] && die "please run as root"}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a Ubuntu Minimal 17.10 laptop\\n"
	echo "Usage:"
	echo "  all 			- do all of the things"
	echo "  base 			- install all the pkgs from apt"
	echo "  code 			- install vs code"
	echo "  docker 			- install docker"
	echo "  go              - install golang"
	echo "  kube 			- install kubernetes things"
	echo "  scripts			- install some cool scripts"
	echo "  spotify			- install spotify"
	echo "  symlinks		- link the config files"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	case $cmd in
		all)
			base
			install_docker
			install_golang
			install_kubectl
			install_scripts
			install_spotify
			symlinks
			echo "Reboot and yipee kay yay!"
			;;
		base)
			base
			;;
		code)
			install_vscode
			;;
		docker)
			install_docker
			;;
		docker-compose)
			install_docker_compose
			;;
		go)
			install_golang
			;;
		kube)
			install_kubectl
			;;
		scripts)
			install_scripts
			;;
		spotify)
			install_spotify
			;;
		symlinks)
			symlinks
			;;
		*)
			usage
			;;
	esac

}

# must run this with sudo to do the thing with the thing
check_is_sudo
main "$@"
