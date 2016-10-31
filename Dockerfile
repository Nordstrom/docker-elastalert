FROM quay.io/nordstrom/python:2.7
MAINTAINER Innovation Platform Team "invcldtm@nordstrom.com"

USER root 

RUN apt-get update -qy \
 && apt-get install -qy \
      unzip \ 
      python-dev \
      gcc

ARG ELASTALERT_VERSION
# Download and unpack Elastalert.
RUN curl -L -o /tmp/elastalert.zip https://github.com/Yelp/elastalert/archive/v${ELASTALERT_VERSION}.zip \
 && unzip -d /tmp /tmp/elastalert.zip \
 && rm /tmp/elastalert.zip \
 && mv /tmp/elastalert-${ELASTALERT_VERSION} /elastalert \
 && mv /elastalert/config.yaml.example /elastalert/config.yaml

WORKDIR /elastalert

# Copy requirements.txt - elasticsearch and configparser version changed
COPY config/requirements.txt /tmp/requirements.txt

# Install Elastalert.
RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install -r /tmp/requirements.txt \
 && pip install datetime \
 && python /elastalert/setup.py install

# Copy prometheus_alertmanager alerter.
RUN mkdir -p /elastalert/elastalert/elastalert_modules
COPY elastalert_modules/__init__.py /elastalert/elastalert/elastalert_modules/__init__.py
COPY elastalert_modules/prometheus_alertmanager.py /elastalert/elastalert/elastalert_modules/prometheus_alertmanager.py

# Copy example_rule (used by start-elastalert.sh)
COPY config/example_rule.yaml /elastalert/example_rule.yaml

# Copy default configuration files to configuration directory.
COPY config/config.yaml.tmpl /elastalert/config.yaml.tmpl
# Copy the script used to launch the Elastalert when a container is started.
COPY config/start-elastalert.sh /elastalert/start-elastalert.sh

# Make the start-script executable.
RUN chmod +x /elastalert/start-elastalert.sh
# Assign write permission to config file
RUN chmod 777 /elastalert 

USER ubuntu

# Launch Elastalert when a container is started.
ENTRYPOINT [ "/opt/elastalert/start-elastalert.sh", "python", "-m", "elastalert.elastalert", "--config", "config.yaml", "--verbose"]
