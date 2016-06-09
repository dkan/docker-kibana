FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

ENV KIBI_44_VERSION 4.4.1-2
ENV KIBI_44_SHA1SUM 040bb6331df0e94e05223681fdd83de9cfa280f9

# Kibi 4.4.1
RUN curl -O "https://codeload.github.com/sirensolutions/kibi/tar.gz/tag-4.4.1-2" && \
    echo "${KIBI_44_SHA1SUM}  tag-${KIBI_44_VERSION}" | sha1sum -c - && \
    tar xzf "tag-${KIBI_44_VERSION}" -C /opt && \
    rm "tag-${KIBI_44_VERSION}"

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibi-tag-${KIBI_44_VERSION}/config/kibi.yml"
ADD templates/opt/kibi-4.4.x/ /opt/kibi-tag-${KIBI_44_VERSION}/config

ADD patches /patches
RUN patch -p1 -d "/opt/kibi-tag-${KIBI_44_VERSION}" < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibi.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibi.sh"]
