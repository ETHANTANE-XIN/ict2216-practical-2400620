FROM node:24-bookworm-slim

WORKDIR /usr/src
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq && \
    rm -rf /var/lib/apt/lists/*
RUN npm install --global @sonar/scan@5.0.0
COPY package.json package-lock.json ./
RUN npm ci
COPY src ./src
COPY public ./public
COPY tests ./tests
COPY sonar-project.properties ./
RUN npm run test:coverage

COPY sonar/scanner-entrypoint.sh /usr/local/bin/run-sonar-scan
RUN chmod 0555 /usr/local/bin/run-sonar-scan

ENTRYPOINT ["/usr/local/bin/run-sonar-scan"]
