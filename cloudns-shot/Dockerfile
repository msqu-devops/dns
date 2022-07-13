FROM alpine
RUN apk --no-cache add bash curl bind-tools
COPY startup.sh /
RUN chmod 777 /startup.sh
CMD ["/startup.sh"]
