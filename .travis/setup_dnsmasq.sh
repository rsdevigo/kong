#!/bin/bash

sudo apt-get update && sudo apt-get install dnsmasq
echo "user=root" > /etc/dnsmasq.conf