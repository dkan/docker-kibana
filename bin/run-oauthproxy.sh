OAUTH2_PROXY_VERSION="2.0.1.linux-amd64.go1.4.2"

exec "/opt/oauth2_proxy" "--upstream=${UPSTREAM_URL}" "--http-address=127.0.0.1:80"
