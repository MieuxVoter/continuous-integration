#!/usr/bin/env bash

REPO=${REPO:-https://github.com/MieuxVoter/}
SITES_FOLDER=${SITES_FOLDER:-HOME/sites/}
SERVER_HOSTNAME=${SERVER_HOSTNAME:-demo.mieuxvoter.fr}
HTTPS=true
echo "DEPLOYING FROM $SITES_FOLDER ON ${SERVER_HOSTNAME}"


_get_latest_source () {
    # Parameter:
    # * repo: name of the repo
    repo=$1

    current_commit=$(git log -n 1 --format=%H)
    git reset --hard ${current_commit}

    if [ -d ".git" ]; then
        git pull
    else
        git clone ${MV_GITHUB}${repo} .
    fi

}


_build_mvapi () {
    { 
	echo DJANGO_DEBUG=off
	echo DJANGO_SECRET_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c50)
        echo DJANGO_ALLOWED_HOSTS=localhost
    } >> .env
    sudo docker-compose up -d
    sudo docker/migrate.sh
}


_build_mvfront_react() {
    echo "REACT_APP_SERVER_URL=/api/" >> .env.local 
    yarn install && \
	yarn global add serve && \
	yarn upgrade && \
	yarn build && \
	{ $(yarn global bin)/serve -s build -l tcp://localhost:3000 & }
    echo $! > serve.pidfile
}


_build () {
# Parameter:
# * repo: name of the repo
    repo=$1

    if [ "$repo" = "mvapi" ]; then
	_build_mvapi
    else
        _build_mvfront_react
    fi
}


deploy () {
    repo=$1
    site_folder=${SITES_FOLDER}${repo}
    mkdir -p $site_folder

    pushd $site_folder
        echo "Move to folder $site_folder"
        _get_latest_source $repo
        _build $repo
    popd $site_folder
}


setup_nginx () {
	DIR=$(dirname $(dirname "$(readlink -f "$0")"))
	if [ "$HTTP" = true ]; then
		sudo cp $DIR/nginx/http-template.conf /etc/nginx/sites-enabled/${SERVER_HOSTNAME}.conf
	else
		sudo cp $DIR/nginx/https-template.conf /etc/nginx/sites-enabled/${SERVER_HOSTNAME}.conf
	fi

	sudo sed -i "s/HOSTNAME/${SERVER_HOSTNAME}/g" /etc/nginx/sites-enabled/${SERVER_HOSTNAME}.conf
	sudo nginx -s reload
}


echo "DEPLOYING MVAPI"
# deploy mvapi

echo "DEPLOYING MVFRONT-REACT"
# deploy mvfront-react

echo "DEPLOYING NGINX WITH HTTP"
setup_nginx
