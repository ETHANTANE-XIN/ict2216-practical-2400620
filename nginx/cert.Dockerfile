FROM alpine:3.22
RUN apk add --no-cache openssl
COPY generate-certificate.sh /usr/local/bin/generate-certificate
RUN chmod 0555 /usr/local/bin/generate-certificate
ENTRYPOINT ["/usr/local/bin/generate-certificate"]
