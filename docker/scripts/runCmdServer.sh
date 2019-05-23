#!/bin/sh

# detect system platform

unameOutput=`uname -a | awk -v platform='unknown' -v isDarwin='' -v isLinux='' -F ' ' '{ for(i=1;i<=NF;i++){ if($i=="armv7l"){platform="ARM"} else if($i=="Darwin"){platform="Darwin"} else if($i=="Linux" && !match($0, /armv7l/)){platform="Linux"}}; {print platform} }'`

echo `date` "platform type " ${unameOutput} >> cmdServer.log

case "${unameOutput}" in
    Linux)    	platform=linux_x86_64;;
    Darwin)    	platform=darwin_x86_64;;
    ARM)    	platform=linux_arm;;
    *)          platform="UNKNOWN"
esac

echo `date` "cmdServer version " ${platform} >> cmdServer.log

if [[ "${platform}" != "UNKNOWN" ]]; then
    # run cmdServer

    cmdServerFolderName=`echo ${GIT_CMD_SERVER_URL} | sed -n 's/.*\/\([^ ]*\).git/\1/p'`
    echo `date` "cmdServer folder name " ${cmdServerFolderName} >> cmdServer.log

    if [[ ! -d "/${cmdServerFolderName}/" ]]; then
      git clone ${GIT_CMD_SERVER_URL}
    fi

    /${cmdServerFolderName}/bin/${platform}/cmdServer -cmd='grep -i "" | /scripts/generate-site.sh' >> cmdServer.log
fi
