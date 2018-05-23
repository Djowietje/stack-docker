#!/bin/bash

set -euo pipefail

cacert=/usr/share/kibana/config/ca/ca.crt
# Wait for ca file to exist before we continue. If the ca file doesn't exist
# then something went wrong.
while [ ! -f $cacert ]
do
  sleep 2
done
ls -l $cacert

es_url=https://elastic:${ELASTIC_PASSWORD}@elasticsearch:9200
# Wait for Elasticsearch to start up before doing anything.
until curl -s --cacert $cacert $es_url -o /dev/null; do
    sleep 1
done

# Set the password for the kibana user.
# REF: https://www.elastic.co/guide/en/x-pack/6.0/setting-up-authentication.html#set-built-in-user-passwords
until curl --cacert $cacert -s -H 'Content-Type:application/json' \
     -XPUT $es_url/_xpack/security/user/kibana/_password \
     -d "{\"password\": \"${ELASTIC_PASSWORD}\"}"
do
    sleep 2
    echo Retrying...
done


echo "=== CREATE Keystore ==="
if [ -f /config/kibana/kibana.keystore ]; then
    echo "Remove old kibana.keystore"
    rm /config/kibana/kibana.keystore
fi
/usr/share/kibana/bin/kibana-keystore create
echo "Setting elasticsearch.password..."
echo "$ELASTIC_PASSWORD" | /usr/share/kibana/bin/kibana-keystore add 'elasticsearch.password' -x

mv /usr/share/kibana/data/kibana.keystore /config/kibana/kibana.keystore
