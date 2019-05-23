#!/bin/sh

echo `date` "start build site" > ${HOME}/docker-runner.log

while read request
do
    requestSignature=`echo ${request} | awk '$0 ~ /X-Hub-Signature/ {gsub(/X-Hub-Signature: sha1=/,""); print }' | sed 's/[^a-zA-Z0-9]//g'`
#    echo `date` "requestSignature " ${requestSignature} >> ${HOME}/docker-runner.log
    requestBody=`echo ${request} | grep github.com`
#    echo `date` "request " ${request} >> ${HOME}/docker-runner.log

    if [[ ! -z "$requestSignature" ]]
     then
        XHubSignature=${requestSignature}
    fi

    if [[ ! -z "${requestBody}" ]]
     then
        webhookBody=${requestBody}
    fi

    if [[ ! -z "${XHubSignature}"  && ! -z "${webhookBody}" ]]
     then
        # compare HTTP_X_HUB_SIGNATURE with ${GITHUB_SECRET} - docker environment

        locallyGeneratedHMAC=`echo -n ${webhookBody} | openssl sha1 -hmac ${GITHUB_SECRET} | awk '$0 ~ /\(stdin\)= / {gsub(/\(stdin\)= /,""); print }'`
        #echo `date` "XHubSignature " ${XHubSignature} >> ${HOME}/docker-runner.log
        #echo `date` "locallyGeneratedHMAC " ${locallyGeneratedHMAC} >> ${HOME}/docker-runner.log

        if [[ ${XHubSignature} == ${locallyGeneratedHMAC} ]]
         then
            echo `date` "got trusted webhook body " ${webhookBody} >> ${HOME}/docker-runner.log

            # check keyword 'deploy!'
            messageKeyword=`echo ${webhookBody} | jq '.head_commit.message' | sed 's/\"//g'`

            #echo `date` "INIT_KEYWORD " ${INIT_KEYWORD} >> ${HOME}/docker-runner.log
            #echo `date` "if commit message contain keyword 'deploy!' " ${messageKeyword} >> ${HOME}/docker-runner.log

            if [[ ${INIT_KEYWORD} == ${messageKeyword} ]]
             then
                # grep git variables
                GIT_URL=`echo ${webhookBody} | jq -r '.repository.ssh_url'`
                GIT_EMAIL=`echo ${webhookBody} | jq -r '.head_commit.committer.email'`
                GIT_NAME=`echo ${webhookBody} | jq -r '.head_commit.committer.name'`

                echo `date` "git variables GIT_URL, " ${GIT_URL} ${GIT_EMAIL} ${GIT_NAME} >> ${HOME}/docker-runner.log

                # clone repo if repo doesn't exist
                folderName=`echo ${GIT_URL} | sed -n 's/.*\/\([^ ]*\).git/\1/p'`

                if [[ ! -d "/${folderName}/" ]]; then
                  echo `date` "cloning repository into " ${folderName} >> ${HOME}/docker-runner.log
                  git clone ${GIT_URL}
                fi

                cd ${folderName}

                # run site_builder
                unameOutput=`uname -a | awk -v platform='unknown' -v isDarwin='' -v isLinux='' -F ' ' '{ for(i=1;i<=NF;i++){ if($i=="armv7l"){platform="ARM"} else if($i=="Darwin"){platform="Darwin"} else if($i=="Linux" && !match($0, /armv7l/)){platform="Linux"}}; {print platform} }'`

                echo `date` "platform type " ${unameOutput} >> ${HOME}/docker-runner.log

                case "${unameOutput}" in
                    Linux)    	platform=linux_x86_64;;
                    Darwin)    	platform=darwin_x86_64;;
                    ARM)    	platform=linux_arm;;
                    *)          platform="UNKNOWN"
                esac

                if [[ "${platform}" != "UNKNOWN" ]]; then
                    echo `date` "run generate site"  >> ${HOME}/docker-runner.log
                    bin/${platform}/site_builder -generate -folder . >&1 >> ${HOME}/docker-runner.log

                    git config --global user.email ${GIT_EMAIL}
                    git config --global user.name ${GIT_NAME}
                    git add .
                    git commit -m "site built at `date +'%Y-%m-%d %H:%M:%S'`"
                    git status >> ${HOME}/docker-runner.log
                    git push >> ${HOME}/docker-runner.log

                    echo `date` "finish build site" >> ${HOME}/docker-runner.log
                fi
            fi
         else
           echo `date` "could not verify request signature" >> ${HOME}/docker-runner.log
           echo `date` "X-Hub-Signature " ${XHubSignature} >> ${HOME}/docker-runner.log
           echo `date` "locallyGeneratedHMAC " ${locallyGeneratedHMAC} >> ${HOME}/docker-runner.log
           echo `date` "finish build site" >> ${HOME}/docker-runner.log
        fi
    fi

done < "${1:-/dev/stdin}"
