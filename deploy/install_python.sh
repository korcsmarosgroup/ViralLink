#!/bin/sh
add-apt-repository ppa:deadsnakes/ppa
apt-get update

apt-get -y install python3.6 python3.6-dev python3-setuptools python3-pip
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1
update-alternatives --set python3 /usr/bin/python3.5
add-apt-repository ppa:cran/libgit2
apt-get update
apt-get -y install libgit2-dev
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2
update-alternatives --set python3 /usr/bin/python3.6
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 3
update-alternatives --set python3 /usr/bin/python3.7
pip3 install numpy==1.19.4
pip3 install scipy==1.5.4
pip3 install pandas==1.1.4
pip3 install matplotlib==3.3.3
pip3 install argparse
pip3 install pyfasta==0.5.2
pip3 install networkx==2.5