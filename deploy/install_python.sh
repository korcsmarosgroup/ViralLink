#!/bin/sh
add-apt-repository ppa:deadsnakes/ppa
apt-get update

apt-get -y install python3.6 python3.6-dev python3-setuptools python3-pip
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2
pip3 install --upgrade numpy==1.19.4
pip3 install --upgrade scipy==1.5.4
pip3 install --upgrade pandas==1.1.4
pip3 install --upgrade matplotlib==3.3.3
pip3 install --upgrade argparse
pip3 install --upgrade pyfasta==0.5.2
pip3 install --upgrade networkx==2.5