#!/usr/bin/env bash

MV_GITHUB=https://github.com/MieuxVoter/
DEFAULT_SITE=$HOME/sites/
echo "KILLING SERVERS"

pushd $DEFAULT_SITE/mvapi
	sudo docker-compose down
popd

pushd $DEFAULT_SITE/mvfront_react
	pid=$(cat mvfront_react.pidfile)
	kill $pid
popd
