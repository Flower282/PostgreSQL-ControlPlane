FROM ubuntu:24.04

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY automation /autobase/automation

RUN apt-get clean && rm -rf /var/lib/apt/lists/partial \
  && apt-get update -o Acquire::CompressionTypes::Order::=gz \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    ca-certificates gnupg keychain apt-transport-https \
    git python3 python3-dev python3-pip openssh-client sshpass gcc g++ cmake make libssl-dev curl lsb-release \
  && pip3 install --break-system-packages --no-cache-dir --retries 3 --timeout 60 \
    -r /autobase/automation/requirements.txt \
  && ansible-galaxy install --force -r /autobase/automation/requirements.yml \
  && ansible-galaxy collection list \
  && apt-get autoremove -y --purge gnupg git python3-dev gcc g++ cmake make libssl-dev \
  && apt-get clean -y autoclean \
  && rm -rf /var/lib/apt/lists/* /tmp/* \
  && chmod +x /autobase/automation/entrypoint.sh

RUN mkdir -p /root/.ansible/collections/ansible_collections/vitabaks \
  && ln -sfn /autobase/automation /root/.ansible/collections/ansible_collections/vitabaks/autobase

ENV ANSIBLE_COLLECTIONS_PATH=/root/.ansible/collections:/usr/local/lib/python3.12/dist-packages
ENV ANSIBLE_CONFIG=/autobase/automation/ansible.cfg
ENV USER=root

WORKDIR /autobase/automation/playbooks

ENTRYPOINT ["/autobase/automation/entrypoint.sh"]