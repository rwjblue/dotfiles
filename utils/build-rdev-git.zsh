#!/usr/bin/env zsh

echo "Installing dependencies for git"
sudo yum install -y curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel

echo "Downloading Git source"
DESIRED_GIT_VERSION="2.40.1"
cd /usr/src
sudo wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-${DESIRED_GIT_VERSION}.tar.gz
sudo tar xzf git-${DESIRED_GIT_VERSION}.tar.gz
cd git-${DESIRED_GIT_VERSION}

echo "Compiling and installing Git"
sudo make prefix=/usr/local all
sudo make prefix=/usr/local install

git --version
