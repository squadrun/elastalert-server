FROM alpine:latest as py-ea
ARG ELASTALERT_VERSION=v0.2.4
ENV ELASTALERT_VERSION=${ELASTALERT_VERSION}
# URL from which to download Elastalert.
ARG ELASTALERT_URL=https://github.com/Yelp/elastalert/archive/$ELASTALERT_VERSION.zip
ENV ELASTALERT_URL=${ELASTALERT_URL}
# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert

WORKDIR /opt

RUN apk add --update --no-cache ca-certificates openssl-dev openssl python3-dev python3 py3-pip libffi-dev gcc build-base musl-dev wget && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv e* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
# see: https://github.com/Yelp/elastalert/issues/1654
RUN pip3 install setuptools &&  \
    python3 setup.py install && pip3 install apscheduler>=3.3.0 aws-requests-auth>=0.3.0 blist>=1.3.6 boto3>=1.4.4 cffi>=1.11.5 configparser>=3.5.0 croniter>=0.3.16 elasticsearch>=7.0.0 envparse>=0.2.0 exotel>=0.1.3 jira jsonschema>=3.0.2 mock>=2.0.0 prison>=0.1.2 py-zabbix==1.1.3 PyStaticConfiguration>=0.10.3 python-dateutil>=2.6.0 python-magic>=0.4.15 PyYAML>=5.1 requests>=2.0.0 stomp.py>=4.1.17 texttable>=0.8.8 twilio==6.0.0

FROM node:alpine
LABEL maintainer="BitSensor <dev@bitsensor.io>"
# Set timezone for this container
ENV TZ Etc/UTC

RUN apk add --update --no-cache curl tzdata python3 make libmagic

# COPY --from=py-ea /usr/lib/python3.6/site-packages /usr/lib/python3.6/site-packages
COPY --from=py-ea /opt/elastalert /opt/elastalert
# COPY --from=py-ea /usr/bin/elastalert* /usr/bin/

WORKDIR /opt/elastalert-server
COPY . /opt/elastalert-server

RUN npm install --production --quiet
COPY config/elastalert.yaml /opt/elastalert/config.yaml
COPY config/elastalert-test.yaml /opt/elastalert/config-test.yaml
COPY config/config.json config/config.json
COPY rule_templates/ /opt/elastalert/rule_templates
COPY elastalert_modules/ /opt/elastalert/elastalert_modules

# Add default rules directory
# Set permission as unpriviledged user (1000:1000), compatible with Kubernetes
RUN mkdir -p /opt/elastalert/rules/ /opt/elastalert/server_data/tests/ \
    && chown -R node:node /opt

RUN ln -s /usr/bin/python3 /usr/bin/python


USER node

EXPOSE 3030
ENTRYPOINT ["sh"]
