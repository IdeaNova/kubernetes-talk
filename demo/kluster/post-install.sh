#!/bin/bash
provision_marker=/var/local/.provisioned
if [ ! -f ${provision_marker} ]; then
    at -f /vagrant/post-install-job.sh now +1 minutes
    touch ${provision_marker}
fi