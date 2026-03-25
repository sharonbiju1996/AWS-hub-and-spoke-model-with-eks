#!/bin/bash
set -eux 
# Basic cleanup (important for images)
echo "--- Starting cleanup ---"
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
echo "--- Cleanup complete ---"