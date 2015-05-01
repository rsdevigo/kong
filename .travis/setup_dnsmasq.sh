#!/bin/bash

source ./versions.sh

DNSMASQ_BASE=dnsmasq-$DNSMASQ_VERSION

sudo apt-get update && sudo apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make

curl http://www.thekelleys.org.uk/dnsmasq/$DNSMASQ_BASE.tar.gz | tar xz
cd $DNSMASQ_BASE
make && sudo make install
cd $TRAVIS_BUILD_DIR
rm -rf $DNSMASQ_BASE
