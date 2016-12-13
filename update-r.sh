#!/bin/bash

codename=$(lsb_release -c -s)
echo "deb https://cran.cnr.Berkeley.edu/cran/bin/linux/ubuntu $codename/" | sudo tee -a /etc/apt/sources.list > /dev/null

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo add-apt-repository ppa:marutter/rdev -y

sudo apt-get update -y
sudo apt-get install r-base -y
