ARG ARG_VERSION
FROM hashicorp/vault:$ARG_VERSION
COPY ./ca.pem /usr/local/share/ca-certificates/ca.crt
RUN set -eux \
    update-ca-certificates \
    echo $(cat /usr/local/share/ca-certificates/ca.crt) >> /etc/ssl/certs/ca-certificates.crt
