#!/bin/bash

sudo apt-get update && sudo apt-get install dnsmasq
echo "user=root" > sudo /etc/dnsmasq.conf