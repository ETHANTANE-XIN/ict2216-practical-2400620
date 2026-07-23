FROM nginx:1.29-alpine

COPY wait-for-certificate.sh /usr/local/bin/wait-for-certificate
RUN chmod 0555 /usr/local/bin/wait-for-certificate

ENTRYPOINT ["/usr/local/bin/wait-for-certificate"]
