OAUTH2_PROXY_VERSION="2.0.1.linux-amd64.go1.4.2"
UPSTREAM_URL=ENV['UPSTREAM_URL']

exec "/opt/oauth2_proxy -upstream ${UPSTREAM_URL}"
