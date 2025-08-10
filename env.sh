#!/usr/bin/env bash

# In Github Action's servers,We don't need firefox.Update it will take a lot of time.
apt remove firefox
apt autoremove

apt-get update && apt-get upgrade -y
apt-get install python3 git curl ccache libelf-dev \
            build-essential flex bison libssl-dev \
            libncurses-dev liblz4-tool zlib1g-dev \
            libxml2-utils rsync unzip