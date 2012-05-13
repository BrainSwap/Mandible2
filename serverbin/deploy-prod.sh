#!/bin/bash
# Customize this script and put it on your app server
# Setup requires:
# Deploy user that has read-only access to your repo with
# assumes ~/repos/myproject as this repo
# /var/www/html/myapp.com/ as this prod endpoint

echo 'Deploying to production...'
cd ~/repos/myapp/
git checkout master
git reset HEAD --hard
git pull
jake clean:prod
jake build:prod
jake s3:prod
rsync -arL deploy-prod/ /var/www/html/myapp.com/
git show | head -n 8