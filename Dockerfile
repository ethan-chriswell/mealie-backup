FROM alpine:3.20

RUN apk add --no-cache bash git curl samba-client jq

WORKDIR /app

COPY scripts/main.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/bin/bash", "/app/entrypoint.sh"]