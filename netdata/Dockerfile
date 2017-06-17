FROM firehol/netdata

RUN apt-get update && apt-get install -y \
    gcc \
    make

RUN /usr/libexec/netdata/plugins.d/fping.plugin install

RUN apt-get purge -y --auto-remove \
    gcc \
    make \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/sbin/netdata", "-D", "-s", "/host", "-p", "${NETDATA_PORT}"]
