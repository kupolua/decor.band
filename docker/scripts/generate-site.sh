#!/usr/bin/env sh

git clone ${GIT_URL}

folderName=`echo ${GIT_URL} | sed -n 's/.*\/\([^ ]*\).git/\1/p'`

cd $folderName

bin/linux_arm/site_builder -generate -folder .

git config --global user.email ${GIT_EMAIL}
git config --global user.name ${GIT_NAME}
git add .
git commit -m "site built at `date +'%Y-%m-%d %H:%M:%S'`"
git push
