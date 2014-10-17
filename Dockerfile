# nginx autogenerator reverse proxy
#
# Based on:
# https://github.com/nginxinc/docker-nginx/blob/64ce8e442caea8b78ff5ebc144a527fc3f6d6d8b/Dockerfile
# https://github.com/jwilder/nginx-proxy/blob/941f3cc9d2b4bdb97f2c63681dd586cca55e3ee3/Dockerfile
#
# VERSION: see `TAG`
FROM debian:wheezy
MAINTAINER Joao Paulo Dubas "joao.dubas@gmail.com"

# environment variables
ENV NGINX_VERSION 1.7.6-1~wheezy
ENV DOCKER_HOST unix:///tmp/docker.sock

# install system deps
RUN apt-key adv \
        --keyserver pgp.mit.edu \
        --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" \
        >> /etc/apt/sources.list \
    && apt-get -y -qq --force-yes update \
    && apt-get --only-upgrade install bash \
    && apt-get -y -qq --force-yes install nginx=${NGINX_VERSION} wget

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# install external deps
RUN wget --no-check-certificate \
        -P /usr/local/bin \
        https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego \
    && chmod u+x /usr/local/bin/forego \
    && wget --no-check-certificate \
        https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz \
    && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-0.3.3.tar.gz

# improve default conf for nginx
RUN mkdir /etc/nginx/sites-enabled \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && sed -r -i \
        "s/(\s+)(include \/etc\/nginx\/conf[^\;]+;)/\1\2\n\1include \/etc\/nginx\/sites-enabled\/*;\n\1include \/opt\/nginx-proxy\/sites-static\/*;/g" \
        /etc/nginx/nginx.conf

# add default nginx conf template
ADD ./nginx.tmpl /opt/nginx-proxy/default/nginx.tmpl
RUN ln -s /opt/nginx-proxy/default /opt/nginx-proxy/nginx

# configure forego
RUN mkdir -p /opt/nginx-proxy
ADD ./Procfile /opt/nginx-proxy/Procfile

# container conf
EXPOSE 80 443
VOLUME ["/opt/nginx-proxy/nginx", "/opt/nginx-proxy/sites-static"]
WORKDIR /opt/nginx-proxy
CMD ["forego", "start", "-r"]
