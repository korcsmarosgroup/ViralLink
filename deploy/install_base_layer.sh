#!/bin/sh
set -e

apt-get update -y --force-yes

apt-get -y install gcc g++ make sudo apt-utils software-properties-common
echo "----------------- BASIC PACKAGES INSTALLED ---------------------"

apt-get install -y locales
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "LANGUAGE=en_US.UTF-8" >> /etc/environment
echo "LANG=en_US.UTF-8" >> /etc/environment
echo "---------------------- UTF-8 CONFIGURED --------------------"

apt-get -y install screen
echo "-------------- SCREEN INSTALLED ---------------"

apt-get -y install python-dev
echo "---------------------- PYTHON-DEV INSTALLED --------------------"

apt-get install -y nano
echo "---------------------- NANO INSTALLED --------------------"

apt-get install -y links
echo "---------------------- LINKS INSTALLED --------------------"

apt-get install -y git
echo "---------------------- GIT INSTALLED --------------------"

apt-get install -y wget
echo "---------------------- WGET INSTALLED --------------------"

apt-get install -y curl
echo "---------------------- CURL INSTALLED --------------------"

apt-get install -y htop
echo "---------------------- HTOP INSTALLED --------------------"

apt-get install -y supervisor
echo "---------------------- SUPERVISOR INSTALLED --------------------"
