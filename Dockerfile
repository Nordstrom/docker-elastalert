FROM quay.io/nordstrom/python:2.7
MAINTAINER Innovation Platform Team "invcldtm@nordstrom.com"

# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert

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
 && mv /tmp/elastalert-${ELASTALERT_VERSION} ${ELASTALERT_HOME} \
 && mv ${ELASTALERT_HOME}/config.yaml.example ${ELASTALERT_HOME}/config.yaml

WORKDIR ${ELASTALERT_HOME}

# Copy requirements.txt - elasticsearch and configparser version changed
COPY requirements.txt /tmp/requirements.txt

# Install Elastalert.
RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install -r /tmp/requirements.txt \
 && pip install datetime \
 && python ${ELASTALERT_HOME}/setup.py install

# Copy prometheus_alertmanager alerter.
RUN mkdir -p ${ELASTALERT_HOME}/elastalert/elastalert_modules
COPY __init__.py ${ELASTALERT_HOME}/elastalert/elastalert_modules/__init__.py
COPY prometheus_alertmanager.py ${ELASTALERT_HOME}/elastalert/elastalert_modules/prometheus_alertmanager.py

# Copy example_rule (used by start-elastalert.sh)
COPY example_rule.yaml ${ELASTALERT_HOME}/example_rule.yaml

# Copy default configuration files to configuration directory.
COPY config.yaml.tmpl ${ELASTALERT_HOME}/config.yaml.tmpl
# Copy the script used to launch the Elastalert when a container is started.
COPY start-elastalert.sh ${ELASTALERT_HOME}/start-elastalert.sh

# Make the start-script executable.
RUN chmod +x ${ELASTALERT_HOME}/start-elastalert.sh
# Assign write permission to config file
RUN chmod 777 ${ELASTALERT_HOME} 

USER ubuntu

# Launch Elastalert when a container is started.
ENTRYPOINT [ "/opt/elastalert/start-elastalert.sh", "python", "-m", "elastalert.elastalert", "--config", "config.yaml", "--verbose"]
