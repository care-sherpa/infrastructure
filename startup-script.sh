#!/bin/bash
sudo apt update
sudo apt install -y ubuntu-desktop xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp
sudo apt install -y openjdk-17-jdk dotnet-sdk-7.0
sudo snap install rider --classic 