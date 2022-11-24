FROM centos:7.9.2009

ENV NGINX_VERSION 1.21.3
ENV DATA_DIR /home/webdck01/nginx_data
ENV HOME /home/webdck01
ENV INSTALL_DIRECTORY=/tools/mdw/container/base_nginx

ENV LUAJIT_VERSION=2.1-20220111
ENV NGINX_DEV_KIT_VERSION=0.3.1
ENV LUA_NGINX_MODULE_VERSION=0.10.21rc1
ENV LUA_RESTY_CORE_VERSION=0.1.23rc1
ENV LUA_RESTY_LRUCACHE_VERSION=0.11

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
     && mkdir -p ${INSTALL_DIRECTORY}/modules \
     && mkdir -p $DATA_DIR/{html,logs,sites-enabled,stream,temp,modules} /home/webdck01/scripts

RUN curl -o ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION}.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION}.tar.gz --directory ${INSTALL_DIRECTORY}/

# Downloading Lua
RUN curl -kL -o ${INSTALL_DIRECTORY}/modules/luajit2-2.1-20220111.tar.gz https://github.com/openresty/luajit2/archive/v2.1-20220111.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/modules/luajit2-2.1-20220111.tar.gz --directory ${INSTALL_DIRECTORY}/modules \
    && rm ${INSTALL_DIRECTORY}/modules/luajit2-2.1-20220111.tar.gz

# Downloading Nginx development kit
RUN curl -kL -o  ${INSTALL_DIRECTORY}/modules/ngx_devel_kit-0.3.1.tar.gz https://github.com/simplresty/ngx_devel_kit/archive/v0.3.1.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/modules/ngx_devel_kit-0.3.1.tar.gz --directory ${INSTALL_DIRECTORY}/modules \
    && rm ${INSTALL_DIRECTORY}/modules/ngx_devel_kit-0.3.1.tar.gz
# Downloading Nginx Lua Module
RUN curl -kL -o  ${INSTALL_DIRECTORY}/modules/lua-nginx-module-0.10.21rc1.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.21rc1.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/modules/lua-nginx-module-0.10.21rc1.tar.gz --directory ${INSTALL_DIRECTORY}/modules \
    && rm ${INSTALL_DIRECTORY}/modules/lua-nginx-module-0.10.21rc1.tar.gz

# Downloading Resty Core
RUN curl -kL -o  ${INSTALL_DIRECTORY}/modules/lua-resty-core-0.1.23rc1.tar.gz https://github.com/openresty/lua-resty-core/archive/v0.1.23rc1.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/modules/lua-resty-core-0.1.23rc1.tar.gz --directory ${INSTALL_DIRECTORY}/modules \
    && rm ${INSTALL_DIRECTORY}/modules/lua-resty-core-0.1.23rc1.tar.gz

# Downloading Resty LRU Cache
RUN curl -kL -o  ${INSTALL_DIRECTORY}/modules/lua-resty-lrucache-0.11.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v0.11.tar.gz \
    && tar -zxf ${INSTALL_DIRECTORY}/modules/lua-resty-lrucache-0.11.tar.gz --directory ${INSTALL_DIRECTORY}/modules \
    && rm ${INSTALL_DIRECTORY}/modules/lua-resty-lrucache-0.11.tar.gz



##### INSTALL RESTY HTTP



RUN cd $INSTALL_DIRECTORY/modules/luajit2* \
    && make && make install

RUN cd $INSTALL_DIRECTORY/modules/lua-resty-core* \
    && make install

RUN cd $INSTALL_DIRECTORY/modules/lua-resty-lrucache* \
    && make install

RUN cd
RUN find $INSTALL_DIRECTORY/modules -name '*.so' -exec mv {} $DATA_DIR/modules/ \;

RUN export LUAJIT_LIB=/usr/local/lib \
  && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
 && cd ${INSTALL_DIRECTORY}/nginx-${NGINX_VERSION} \
    && TEMP_PATH=$DATA_DIR/temp \
    && ./configure \
    --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
    --add-dynamic-module=$INSTALL_DIRECTORY/modules/ngx_devel_kit-${NGINX_DEV_KIT_VERSION} \
    --add-dynamic-module=$INSTALL_DIRECTORY/modules/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
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

#RUN export LD_LIBRARY_PATH=/usr/local/lib/:/tools/mdw/container/base_nginx/nginx-1.21.3_depl/modules/:$LD_LIBRARY_PATH

#ENV NGINX_MODULES /tools/mdw/container/base_nginx/nginx-1.21.3_depl/modules
#ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$NGINX_MODULES


COPY nginx.main.conf /tools/mdw/container/nginx/conf/nginx.conf

USER webdck01

WORKDIR /home/webdck01/nginx_data
CMD ("/tools/mdw/container/nginx/sbin/nginx")

