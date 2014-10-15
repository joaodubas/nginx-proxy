# nginx autogenerator reverse proxy
#
# VERSION: see `TAG`
FROM ubuntu:14.04
MAINTAINER Jason Wilder jwilder@litl.com

# install Nginx.
RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" \
        > /etc/apt/sources.list.d/nginx-stable-trusty.list \
    && echo "deb-src http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" \
        >> /etc/apt/sources.list.d/nginx-stable-trusty.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C \
    && apt-get update \
    && apt-get install --only-upgrade bash \
    && apt-get install -y -qq --force-yes wget nginx \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

# fix for long server names
RUN sed -i \
        's/# server_names_hash_bucket/server_names_hash_bucket/g' \
        /etc/nginx/nginx.conf \
    && sed -r -i \
        "s/(\s+)([^\*]+\*;)/\1\2\n\1include \/opt\/nginx-proxy\/sites-static\/*;/g" \
        /etc/nginx/nginx.conf

# install external deps
RUN wget \
        -P /usr/local/bin \
        https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego \
    && chmod u+x /usr/local/bin/forego \
    && wget https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz \
    && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-0.3.3.tar.gz

# configure forego
RUN mkdir -p /opt/nginx-proxy
ADD ./Procfile /opt/nginx-proxy/Procfile

# container conf
ENV DOCKER_HOST unix:///tmp/docker.sock
EXPOSE 80
VOLUME ["/opt/nginx-proxy/nginx", "/opt/nginx-proxy/sites-static"]
WORKDIR /opt/nginx-proxy
CMD ["forego", "start", "-r"]
