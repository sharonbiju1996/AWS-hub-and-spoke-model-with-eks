#!/bin/bash
set -eux 
echo "--- Init script ---"

# Update package lists
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update -y
sudo apt install -y zip unzip
sudo apt install -y git
sudo apt install -y jq