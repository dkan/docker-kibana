FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby && \
    apt-get install unzip

ENV KIBI_44_VERSION 4.4.1-2
ENV KIBI_44_SHA1SUM ae53c8085252d938c017c1a5d1540fe0b11b22ff

# Kibi 4.4.1
RUN curl -LOk "https://github.com/sirensolutions/kibi/releases/download/tag-4.4.1-2/kibi-4.4.1-2-linux-x64.zip" && \
    echo "${KIBI_44_SHA1SUM}  kibi-${KIBI_44_VERSION}-linux-x64.zip" | sha1sum -c - && \
    unzip "kibi-${KIBI_44_VERSION}-linux-x64.zip" -d /opt && \
    rm "kibi-${KIBI_44_VERSION}-linux-x64.zip"

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibi-${KIBI_44_VERSION}-linux-x64/config/kibi.yml"
ADD templates/opt/kibi-4.4.x/ /opt/kibi-${KIBI_44_VERSION}-linux-x64/config

ADD patches /patches
RUN patch -p1 -d "/opt/kibi-${KIBI_44_VERSION}-linux-x64" < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

ENV OAUTH2_PROXY_VERSION 2.0.1.linux-amd64.go1.4.2

# Install
RUN curl -sL -o oauth2_proxy.tar.gz \
    "https://github.com/bitly/oauth2_proxy/releases/download/v2.0.1/oauth2_proxy-${OAUTH2_PROXY_VERSION}.tar.gz" \
  && tar xzvf oauth2_proxy.tar.gz \
  && mv oauth2_proxy-${OAUTH2_PROXY_VERSION}/oauth2_proxy /opt \
  && chmod +x /opt/oauth2_proxy \
  && rm -r oauth2_proxy*


# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibi.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibi.sh"]
