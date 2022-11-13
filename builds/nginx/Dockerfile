ARG ARG_VERSION
FROM nginx:$ARG_VERSION
COPY ./ca.pem /usr/local/share/ca-certificates/ca.crt
RUN set -eux \
    update-ca-certificates
