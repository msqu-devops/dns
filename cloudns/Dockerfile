FROM alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

RUN apk add --no-cache python3 py3-pip                          \
    && mkdir /app

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir --no-compile --break-system-packages -r requirements.txt

ENTRYPOINT ["python3"]
CMD ["app.py"]
