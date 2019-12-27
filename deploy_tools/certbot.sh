#!/usr/bin/env bash

echo "Installation of dependencies for certbot"
sudo apt-get install certbot python-certbot-nginx -y

sudo certbot certonly --nginx

