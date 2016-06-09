FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

ENV KIBI_44_VERSION 4.4.1-2
ENV KIBI_44_SHA1SUM 6ab1b53644d86b70659407c84612fbe42625d9bb

# Kibi 4.4.1
RUN curl -LOk "https://github.com/sirensolutions/kibi/releases/download/tag-4.4.1-2/kibi-4.4.1-2-linux-x64.zip" && \
    echo "${KIBI_44_SHA1SUM}  kibi-${KIBI_44_VERSION}-linux-x64.zip" | sha1sum -c - && \
    tar xzf "kibi-${KIBI_44_VERSION}-linux-x64.zip" -C /opt && \
    rm "kibi-${KIBI_44_VERSION}-linux-x64.zip"

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibi-kibi-${KIBI_44_VERSION}-linux-x64.zip/config/kibi.yml"
ADD templates/opt/kibi-4.4.x/ /opt/kibi-kibi-${KIBI_44_VERSION}-linux-x64.zip/config

ADD patches /patches
RUN patch -p1 -d "/opt/kibi-kibi-${KIBI_44_VERSION}-linux-x64.zip" < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibi.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibi.sh"]
