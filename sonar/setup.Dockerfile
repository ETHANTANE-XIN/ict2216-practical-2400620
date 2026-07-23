FROM alpine:3.22

RUN apk add --no-cache curl jq
COPY setup.sh /usr/local/bin/setup-sonarqube
RUN chmod 0555 /usr/local/bin/setup-sonarqube

ENTRYPOINT ["/usr/local/bin/setup-sonarqube"]
