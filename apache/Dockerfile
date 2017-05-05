FROM httpd

RUN apt-get update && apt-get -t jessie-backports install -y \
    libapache2-mod-auth-openidc
RUN ln -s /usr/lib/apache2/modules/mod_auth_openidc.so modules/mod_auth_openidc.so
