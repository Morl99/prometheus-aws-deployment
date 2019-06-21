FROM prom/prometheus:v2.10.0

ADD prometheus.yml /etc/prometheus/
ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]