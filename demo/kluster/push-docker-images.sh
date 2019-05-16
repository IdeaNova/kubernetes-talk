#!/bin/bash

img_file=.images.tar
docker save -o $img_file kubeintro-sample-app
echo images saved
for worker in $(vagrant status | grep worker | awk '{print $1}'); do
    vagrant ssh $worker -c "docker load -i /vagrant/$img_file"
    echo loaded $worker
done