#!/usr/bin/env bash
mkdir -p /vagrant/tmp
# provision asynchronously to allow faster start up
echo 'bash /vagrant/provision.sh' | at now +1 minutes 2>&1 | tee /vagrant/tmp/$(hostname).log