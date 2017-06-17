FROM alpine

RUN apk add --no-cache \
    bash \
 && rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/titpetric/netdata/master/fakenet.sh /
RUN chmod +x /fakenet.sh

ENTRYPOINT ["/fakenet.sh"]
