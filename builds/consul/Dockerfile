#https://github.com/hashicorp/docker-consul
ARG ARG_VERSION
FROM consul:$ARG_VERSION
COPY ./ca.pem /usr/local/share/ca-certificates/ca.crt
RUN set -eux \
    update-ca-certificates
# /etc/ssl/certs/
