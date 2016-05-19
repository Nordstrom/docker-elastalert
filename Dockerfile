FROM nordstrom/python:2.7
MAINTAINER Innovation Platform Team "invcldtm@nordstrom.com"

# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert
# Elastalert rules directory.
ENV RULES_DIRECTORY rules
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
RUN curl -L -o elastalert.zip https://github.com/Yelp/elastalert/archive/master.zip && \
    unzip *.zip && \
    rm *.zip && \
    mv elast* ${ELASTALERT_HOME}

WORKDIR ${ELASTALERT_HOME}

# Install Elastalert.
RUN pip install setuptools && \
    pip install -r requirements.txt && \
    pip install tzlocal && \
    pip install datetime && \
    python ./setup.py install

# Create rules directories. 
RUN mkdir -p ${RULES_DIRECTORY} && \
    mkdir -p elastalert/elastalert_modules

COPY ./__init__.py elastalert/elastalert_modules/__init__.py
COPY ./prometheus_alertmanager.py elastalert/elastalert_modules/prometheus_alertmanager.py

# Copy example rule as elastalert exits on empty rules folder
COPY ./example_rule.yaml ${RULES_DIRECTORY}/example_rule.yaml

# Copy default configuration files to configuration directory.
COPY ./config.yaml ${ELASTALERT_CONFIG}
# Copy the script used to launch the Elastalert when a container is started.
COPY ./start-elastalert.sh start-elastalert.sh

# Make the start-script executable.
RUN chmod +x start-elastalert.sh

# Launch Elastalert when a container is started.
ENTRYPOINT [ "/opt/elastalert/start-elastalert.sh", "python", "-m", "elastalert.elastalert", "--config", "config.yaml", "--verbose"]
