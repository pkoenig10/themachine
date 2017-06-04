FROM titpetric/netdata

RUN apt-get update && apt-get  install -y \
    gcc \
    make

RUN /usr/libexec/netdata/plugins.d/fping.plugin install
