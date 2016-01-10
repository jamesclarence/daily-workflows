###
# Rough server installation script.
# To restore server, first try using backup AMI.
###

# install encryption tools

sudo apt-get update
sudo apt-get install ecryptfs-utils cryptsetup -y
sudo apt-get install encfs -y

encfs ~/.app ~/app
# use p mode


# node
sudo rm /usr/bin/node
sudo apt-get install nodejs npm -y
sudo ln -s /usr/bin/nodejs /usr/bin/node

# python
sudo apt-get install python-pip -y


# phantomjs
sudo apt-get install libfontconfig1
cd /usr/local/share/
wget https://phantomjs.googlecode.com/files/phantomjs-1.9.8-linux-x86_64.tar.bz2
tar xjf phantomjs-1.9.8-linux-x86_64.tar.bz2
rm -f phantomjs-1.9.8-linux-x86_64.tar.bz2
ln -s phantomjs-1.9.8-linux-x86_64 phantomjs
sudo ln -s /usr/local/share/phantomjs/bin/phantomjs /usr/bin/phantomjs

# casper
sudo npm install -g casperjs

# R
./update-r.sh

# R "reshape" package
R
install.packages("reshape")
y
y
q()
n

# R "dplyr" package
R
install.packages("dplyr")
0
q()
n

sudo apt-get install secure-delete

# csv2xls, make sure its executable
pip install --user csv2xls
