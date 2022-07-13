FROM alpine:3.11
RUN apk add --no-cache curl bind-tools
COPY startup.sh /
RUN chmod 777 /startup.sh
CMD ["/startup.sh"]
