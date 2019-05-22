FROM alpine:latest

RUN apk update && \
    apk upgrade && \
    apk add --no-cache openssh git openssl jq

RUN mkdir scripts
COPY scripts/runCmdServer.sh / /
COPY scripts/generate-site.sh /scripts

RUN chmod 700 /runCmdServer.sh
RUN chmod 700 /scripts/generate-site.sh

ENTRYPOINT ["/runCmdServer.sh"]
