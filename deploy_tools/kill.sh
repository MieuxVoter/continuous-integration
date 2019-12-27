#!/usr/bin/env bash

MV_GITHUB=https://github.com/MieuxVoter/
DEFAULT_SITE=$HOME/sites
echo "KILLING SERVERS"

pushd $DEFAULT_SITE/mvapi
	sudo docker-compose down
popd

pushd $DEFAULT_SITE/mvfront-react
	pid=$(cat serve.pidfile)
	kill $pid
	rm serve.pidfile
popd
