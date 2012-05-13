#!/bin/bash
# Customize this script and put it on your app server
# Setup requires:
# Deploy user that has read-only access to your repo with
# ~/repos/myproject as this repo
# /var/www/html/myapp.com/ as this prod endpoint

echo 'Deploying to qa...'
cd ~/repos/myapp/
git checkout master
git reset HEAD --hard
git pull
jake clean:prod
jake build:qa
jake s3:qa
rsync -arL deploy-prod/ /var/www/html/qa.myapp.com/
git show | head -n 8