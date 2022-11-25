ARG NGINX_VERSION
FROM nginx:$NGINX_VERSION
COPY ./ca.pem /usr/local/share/ca-certificates/ca.crt
RUN set -eux \
    update-ca-certificates \
    echo $(cat /usr/local/share/ca-certificates/ca.crt) >> /etc/ssl/certs/ca-certificates.crt
