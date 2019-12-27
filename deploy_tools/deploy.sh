#!/usr/bin/env bash

MV_GITHUB=https://github.com/MieuxVoter/
DEFAULT_SITE=$HOME/sites/
echo "DEPLOYING on $DEFAULT_SITE"


_get_latest_source () {
    # Parameter:
    # * repo: name of the repo
    repo=$1

    if [ -d ".git" ]; then
        git fetch
    else
        git clone ${MV_GITHUB}${repo} .
    fi

    current_commit=$(git log -n 1 --format=%H)
    git reset --hard ${current_commit}
}


_build_mvapi () {
    { 
	echo DJANGO_DEBUG=on
	echo DJANGO_SECRET_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c50)
        echo DJANGO_ALLOWED_HOSTS=localhost
    } >> .env
    sudo ./build.sh
    sudo docker-compose up -d
    sudo ./migrate.sh
    # docker exec -it mvapi_web_1 python manage.py collectstatic --noinput
}


_build_mvfront_react() {
    npm install
    npm run build
    sudo npm install serve
    serve -s build -l 3000 &
    echo $! > mvfront_react.pidfile
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
    site_folder=${DEFAULT_SITE}${repo}
    mkdir -p $site_folder

    pushd $site_folder
        echo "Move to folder $site_folder"
        _get_latest_source $repo
        _build $repo
    popd $site_folder
}


echo "DEPLOYING MVAPI"
deploy mvapi

echo "DEPLOYING MVFRONT-REACT"
deploy mvfront-react

echo "DEPLOYING NGINX WITH HTTP"
DIR=$(dirname "$(readlink -f "$0")")
sudo ln -s $DIR/nginx/http-template.conf /etc/nginx/sites-enabled/
/etc/init.d/nginx restart
