#!/bin/bash
#shellcheck disable=SC2086
{
  : ${AUTH_CREDENTIALS:?"Error: environment variable AUTH_CREDENTIALS should be populated with a comma-separated list of user:password pairs. Example: \"admin:pa55w0rD\"."}
  : ${DATABASE_URL:?"Error: environment variable DATABASE_URL should be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}
}

# Parse auth credentials, add to a htpasswd file.
AUTH_PARSER="
create_opt = 'c'
ENV['AUTH_CREDENTIALS'].split(',').map do |creds|
  user, password = creds.split(':')
  %x(htpasswd -b#{create_opt} /etc/nginx/conf.d/kibi.htpasswd #{user} #{password})
  create_opt = ''
end"

ruby -e "$AUTH_PARSER" || {
  echo "Error creating htpasswd file from credentials '$AUTH_CREDENTIALS'"
  exit 1
}

erb -T 2 -r uri -r base64 ./kibi.erb > /etc/nginx/sites-enabled/kibi || {
  echo "Error creating nginx configuration from Elasticsearch url '$DATABASE_URL'"
  exit 1
}

# If we don't have a version set, then try to guess one form the Elasticsearch server.
if [[ -z "$KIBI_ACTIVE_VERSION" ]]; then
  KIBI_VERSION_PARSER="
  require 'json'
  version = JSON.parse(STDIN.read)['version']['number']
  print version.start_with?('1.') ? 41 : 44"
  KIBI_ACTIVE_VERSION="$(curl "$DATABASE_URL" 2>/dev/null | ruby -e "$KIBI_VERSION_PARSER" 2>/dev/null)"
fi

# If we still don't have a version, fall back to the default.
if [[ -z "$KIBI_ACTIVE_VERSION" ]]; then
    echo "Warning: unable to fetch Elasticsearch version, and none configured. Defaulting to 4.4. Consider setting KIBI_ACTIVE_VERSION."
    KIBI_ACTIVE_VERSION="44"
fi

echo "KIBI_ACTIVE_VERSION is set to: '$KIBI_ACTIVE_VERSION'"

KIBI_VERSION_PTR="KIBI_${KIBI_ACTIVE_VERSION}_VERSION"
KIBI_VERSION="${!KIBI_VERSION_PTR}"

# Run config
erb -T 2 -r uri "/opt/kibi-${KIBI_VERSION}/config/kibi.yml.erb" > "/opt/kibi-${KIBI_VERSION}-linux-x64/config/kibi.yml" || {
  echo "Error creating kibi config file"
  exit 1
}

service nginx start

: ${NODE_OPTIONS:="--max-old-space-size=256"}

export NODE_OPTIONS
exec "/opt/kibi-${KIBI_VERSION}-linux-x64/bin/kibi"
