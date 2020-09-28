#!/bin/sh
apt-get -y purge r-base* r-base-core* r-recommended r-cran-*
apt-get -y install apt-transport-https

bash -c 'echo "deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran40/" >> /etc/apt/sources.list'
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
apt-get update

apt-get -y install r-base r-base-core r-base-dev
apt-get -y install r-cran-curl r-cran-openssl r-cran-xml2
apt-get -y install libcurl4-openssl-dev
apt-get -y install libxml2-dev
apt-get -y install libssl-dev
