FROM nordstrom/python:2.7
MAINTAINER Innovation Platform Team "invcldtm@nordstrom.com"

# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert
# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${ELASTALERT_HOME}/config.yaml


# Install curl
RUN apt-get update -y \
    && apt-get install -y \
    curl \
    unzip \ 
    python-dev \
    gcc \ 
    musl-dev

# Download and unpack Elastalert.
RUN curl -L -o elastalert.zip https://github.com/Yelp/elastalert/archive/v0.0.81.zip && \
    unzip *.zip && \
    rm *.zip && \
    mv elast* ${ELASTALERT_HOME}

WORKDIR ${ELASTALERT_HOME}

# Install Elastalert.
RUN pip install setuptools && \
    pip install -r requirements.txt && \
    pip install datetime && \
    python ./setup.py install

# Copy prometheus_alertmanager alerter.
RUN mkdir -p elastalert/elastalert_modules
COPY ./__init__.py elastalert/elastalert_modules/__init__.py
COPY ./prometheus_alertmanager.py elastalert/elastalert_modules/prometheus_alertmanager.py

# Copy example_rule (used by start-elastalert.sh)
COPY ./example_rule.yaml example_rule.yaml

# Copy default configuration files to configuration directory.
COPY ./config.yaml ${ELASTALERT_CONFIG}
# Copy the script used to launch the Elastalert when a container is started.
COPY ./start-elastalert.sh start-elastalert.sh

# Make the start-script executable.
RUN chmod +x start-elastalert.sh

# Launch Elastalert when a container is started.
ENTRYPOINT [ "/opt/elastalert/start-elastalert.sh", "python", "-m", "elastalert.elastalert", "--config", "config.yaml", "--verbose"]
