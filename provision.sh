#!/bin/bash

# Install dependencies
#sudo apt-get install -y build-essential libxml2-dev software-properties-common python-software-properties
sudo apt-get install -y nodejs build-essential libxml2-dev npm

# Install nodejs
#sudo add-apt-repository -y ppa:chris-lea/node.js
#sudo apt-get update -y
#sudo apt-get install -y nodejs

# Install redis
#sudo apt-get install -y redis-server

# Create symlink for node to nodejs
sudo ln -s $(which nodejs) /usr/local/bin/node

# ApiAxle setup
cd /vagrant
make npminstall
sudo make link clean

# Install coffeescript and twerp
sudo npm install -g coffee-script twerp

# Execute tests
make test