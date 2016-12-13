FROM frolvlad/alpine-glibc

RUN  apk add --update bash \
 &&  rm -rf /var/cache/apk/*

RUN  apk add --update util-linux \
 &&  cp /usr/bin/script /tmp/script \
 &&  apk del util-linux \
 &&  rm -rf /var/cache/apk/* \
 &&  mv /tmp/script /usr/bin/script

ENV  TINI_VERSION=v0.13.0
RUN  apk add --update curl \
 &&  curl -sL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 \
  |  install -m 0755 /dev/stdin /bin/tini \
 &&  apk del curl \
 &&  rm -rf /var/cache/apk/*


ADD  pause  /bin/pause
ADD  jq     /bin/jq
ADD  docker /bin/docker

ADD  bin/   /bin/

ENTRYPOINT ["foreign-root-loader"]
ADD  entrypoint /bin/foreign-root-loader
