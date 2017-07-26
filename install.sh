#!/bin/bash

sudo apt-get update
sudo apt-get install -y android-tools-adb
sudo apt-get install -y libxml2-utils

sudo service udev restart
