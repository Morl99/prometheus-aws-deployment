#!/bin/sh
# Use pipe as separator for sed, since the key might contain slashes
sed -i "s|\${SECRET}|$SECRET|g" /etc/prometheus/prometheus.yml
sed -i "s|\${KEY_ID}|$KEY_ID|g" /etc/prometheus/prometheus.yml
cat /etc/prometheus/prometheus.yml
# TODO somehow using $@ does not work, so I copied over the original command parameters from the upstream Dockerfile.
# Probably a stupid mistake, but I do not want to loose too much time on this.
exec /bin/prometheus \
 "--config.file=/etc/prometheus/prometheus.yml" \
 "--storage.tsdb.path=/prometheus" \
 "--web.console.templates=/usr/share/prometheus/consoles" \
 "--web.console.libraries=/usr/share/prometheus/console_libraries"