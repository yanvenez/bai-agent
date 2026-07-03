FROM nousresearch/hermes-agent:latest

ENV HERMES_HOME=/opt/data

# Install proxy deps using system pip (bypass venv)
COPY requirements-proxy.txt /tmp/requirements-proxy.txt
RUN /opt/hermes/.venv/bin/python3 -m ensurepip --upgrade 2>/dev/null || true
RUN /opt/hermes/.venv/bin/python3 -m pip install --no-cache-dir -r /tmp/requirements-proxy.txt 2>/dev/null \
    || (apt-get update -qq && apt-get install -y -qq python3-pip && pip3 install --no-cache-dir -r /tmp/requirements-proxy.txt)

# Copy files
COPY bai_proxy.py /opt/bai_proxy.py
COPY bai_apikeys.txt /opt/bai_apikeys.txt
COPY provider.conf /opt/data/provider.conf
COPY bootstrap.sh /opt/bootstrap.sh
RUN chmod +x /opt/bootstrap.sh

CMD ["/opt/bootstrap.sh"]
