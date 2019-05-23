## to run container

# forward local generate-site.sh into docker
docker run -ti --name site-builder --rm -p 4567:8080 -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/projects/nika/docker/scripts:/scripts -e GITHUB_SECRET='228jTJmvQefA7EUUbiz1oT54v9jafBnlCjlWV3ZWBv05Chj0wFcVi2B6sRRWe8Kl' -e GIT_CMD_SERVER_URL='https://github.com/agapeteo/cmdServer.git' -e INIT_KEYWORD='deploy!' kupolua/site-builder sh

# copy generate-site.sh into docker
docker run -t --name site-builder --rm -p 4567:8080 -v ${HOME}/.ssh:/root/.ssh -e GITHUB_SECRET='228jTJmvQefA7EUUbiz1oT54v9jafBnlCjlWV3ZWBv05Chj0wFcVi2B6sRRWe8Kl' -e GIT_CMD_SERVER_URL='https://github.com/agapeteo/cmdServer.git' -e INIT_KEYWORD='deploy!' kupolua/site-builder

# build docker 
docker kill site-builder && docker rmi kupolua/site-builder && docker build -t kupolua/site-builder:latest .
