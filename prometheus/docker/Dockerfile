FROM prom/prometheus:v2.10.0

ADD prometheus.yml /etc/prometheus/
ADD entrypoint.sh /etc/prometheus/
USER root
RUN chmod +x /etc/prometheus/entrypoint.sh
USER nobody
ENTRYPOINT ["/etc/prometheus/entrypoint.sh"]