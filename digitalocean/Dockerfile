FROM alpine
RUN apk --no-cache add curl jq
COPY dyndns.sh /
USER nobody
ENTRYPOINT exec /dyndns.sh
