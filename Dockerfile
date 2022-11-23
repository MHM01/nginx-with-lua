FROM centos:7.9.2009

ENV NGINX_VERSION 1.21.3
ENV DATA_DIR /home/webdck01/nginx_data
ENV HOME /home/webdck01
ENV INSTALL_DIRECTORY=/tools/mdw/container/base_nginx

ENV LUAJIT_VERSION=2.1-20200102
ENV NGINX_DEV_KIT_VERSION=0.3.1
ENV LUA_NGINX_MODULE_VERSION=0.10.12
ENV LUA_RESTY_CORE_VERSION=0.1.17
ENV LUA_RESTY_LRUCACHE_VERSION=0.09

RUN set -x \
    && yum makecache fast \
    && yum -y install \
    perl \
    perl-ExtUtils-Embed \
    tar \
    gcc-c++ \
    pcre-devel \
    openssl-devel \
    make

RUN groupadd -r webadm \
    && useradd -c "med.mas" -r --create-home -g webadm webdck01

RUN  umask 022 \
     && mkdir -p ${INSTALL_DIRECTORY} \
     && mkdir -p $DATA_DIR/{html,logs,sites-enabled,stream,temp,modules} /home/webdck01/scripts

RUN curl -o ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION}.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION}.tar.gz --directory ${INSTALL_DIRECTORY}/

## Downloading Lua
#RUN curl -k -o ${DATA_DIR}/modules/luajit2-${LUAJIT_VERSION}.tar.gz "https://github.com/openresty/luajit2/archive/v${LUAJIT_VERSION}.tar.gz"
#
## Downloading Nginx development kit
#RUN curl -k -o  ${DATA_DIR}/modules/ngx_devel_kit-${NGINX_DEV_KIT_VERSION}.tar.gz "https://github.com/simplresty/ngx_devel_kit/archive/v${NGINX_DEV_KIT_VERSION}.tar.gz"
#
## Downloading Nginx Lua Module
#RUN curl -k -o  ${DATA_DIR}/modules/lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz "https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.tar.gz"
#
## Downloading Resty Core
#RUN curl -k -o  ${DATA_DIR}/modules/lua-resty-core-${LUA_RESTY_CORE_VERSION}.tar.gz "https://github.com/openresty/lua-resty-core/archive/v${LUA_RESTY_CORE_VERSION}.tar.gz"
#
## Downloading Resty LRU Cache
#RUN curl -k -o  ${DATA_DIR}/modules/lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}.tar.gz "https://github.com/openresty/lua-resty-lrucache/archive/v${LUA_RESTY_LRUCACHE_VERSION}.tar.gz"

# Downloading Lua
RUN curl -kL -o ${DATA_DIR}/modules/luajit2-2.1-20200102.tar.gz https://github.com/openresty/luajit2/archive/v2.1-20200102.tar.gz \
    && tar -zxf ${DATA_DIR}/modules/luajit2-2.1-20200102.tar.gz --directory ${DATA_DIR}/modules

# Downloading Nginx development kit
RUN curl -kL -o  ${DATA_DIR}/modules/ngx_devel_kit-0.3.1.tar.gz https://github.com/simplresty/ngx_devel_kit/archive/v0.3.1.tar.gz \
    && tar -zxf ${DATA_DIR}/modules/ngx_devel_kit-0.3.1.tar.gz --directory ${DATA_DIR}/modules

# Downloading Nginx Lua Module
RUN curl -kL -o  ${DATA_DIR}/modules/lua-nginx-module-0.10.12.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.12.tar.gz \
    && tar -zxf ${DATA_DIR}/modules/lua-nginx-module-0.10.12.tar.gz --directory ${DATA_DIR}/modules

# Downloading Resty Core
RUN curl -kL -o  ${DATA_DIR}/modules/lua-resty-core-0.1.17.tar.gz https://github.com/openresty/lua-resty-core/archive/v0.1.17.tar.gz \
    && tar -zxf ${DATA_DIR}/modules/lua-resty-core-0.1.17.tar.gz --directory ${DATA_DIR}/modules

# Downloading Resty LRU Cache
RUN curl -kL -o  ${DATA_DIR}/modules/lua-resty-lrucache-0.09.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v0.09.tar.gz \
    && tar -zxf ${DATA_DIR}/modules/lua-resty-lrucache-0.09.tar.gz --directory ${DATA_DIR}/modules

#RUN cd $DATA_DIR/modules \
#    && find . -type f -name '*.tar.gz' -exec tar -xzf {} \
#    && rm -rf *.gz

RUN cd $DATA_DIR/modules/luajit2* \
    && make && make install

RUN cd $DATA_DIR/modules/lua-resty-core* \
    && make install

RUN cd $DATA_DIR/modules/lua-resty-lrucache* \
    && make install


RUN export LUAJIT_LIB=/usr/local/lib \
  && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
 && cd ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION} \
    && TEMP_PATH=$DATA_DIR/temp \
    && ./configure \
    --add-dynamic-module=$DATA_DIR/modules/ngx_devel_kit-${NGINX_DEV_KIT_VERSION} \
    --add-dynamic-module=$DATA_DIR/modules/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
#    --add-dynamic-module=$DATA_DIR/modules/luajit2-${LUAJIT_VERSION} \
    --prefix=/tools/mdw/container/base_nginx/nginx-${NGINX_VERSION}_depl \
    --error-log-path=$DATA_DIR/logs/error.log \
    --http-log-path=$DATA_DIR/logs/access.log \
    --pid-path=$DATA_DIR/logs/nginx.pid \
    --with-http_ssl_module \
    --with-stream \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_perl_module \
    --with-http_auth_request_module \
    --with-http_v2_module \
    --http-client-body-temp-path=$TEMP_PATH/client_body_temp \
    --http-proxy-temp-path=$TEMP_PATH/proxy_temp \
    --http-fastcgi-temp-path=$TEMP_PATH/fastcgi_temp \
    --http-uwsgi-temp-path=$TEMP_PATH/uwsgi_temp \
    --http-scgi-temp-path=$TEMP_PATH/scgi_temp \
    && make \
    && make modules \
    && make install\
    && ln -s /tools/mdw/container/base_nginx/nginx-${NGINX_VERSION}_depl /tools/mdw/container/nginx \
    && cd /tools/mdw/container/nginx/conf \
    && mkdir {ssl.crt,ssl.key} \
    && chown -R webdck01:webadm /home/webdck01/* \
    && yum -y remove \
    make \
    gcc-c++ \
    pcre-devel \
    openssl-devel \
    && yum clean all

COPY nginx.main.conf /tools/mdw/container/nginx/conf/nginx.conf

USER webdck01

WORKDIR /home/webdck01/nginx_data

CMD ("/tools/mdw/container/nginx/sbin/nginx")

