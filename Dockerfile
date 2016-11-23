FROM quay.io/nordstrom/python:2.7
MAINTAINER Innovation Platform Team "invcldtm@nordstrom.com"

ARG ELASTALERT_VERSION

USER root 

RUN apt-get update -qy \
 && apt-get install -qy \
      unzip \ 
      python-dev \
      gcc

RUN curl -L -o /tmp/elastalert.zip https://github.com/Yelp/elastalert/archive/v${ELASTALERT_VERSION}.zip \
 && unzip -d /tmp /tmp/elastalert.zip \
 && rm /tmp/elastalert.zip \
 && mv /tmp/elastalert-${ELASTALERT_VERSION} /elastalert \
 && mv /elastalert/config.yaml.example /elastalert/config.yaml

COPY config/ /elastalert/

# Copy requirements.txt - elasticsearch and configparser version changed
RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install -r /elastalert/requirements.txt \
 && pip install datetime \
 && python /elastalert/setup.py install

COPY elastalert_modules /elastalert/elastalert/elastalert_modules

RUN chown -R ubuntu /elastalert \
 && chmod 777 /elastalert

USER ubuntu

WORKDIR /elastalert

ENTRYPOINT [ "python", "-m", "elastalert.elastalert" ]
