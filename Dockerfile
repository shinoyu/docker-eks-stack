ARG AWS_CLI_VERSION=1.18.72
ARG TERRAFORM_VERSION=0.12.28
ARG PYTHON_MAJOR_VERSION=3.7
ARG DEBIAN_VERSION=buster-slim

FROM debian:${DEBIAN_VERSION} as terraform
ARG TERRAFORM_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    gnupg
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

FROM debian:${DEBIAN_VERSION} as aws-cli
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip
RUN pip3 install setuptools && \
    pip3 install awscli==${AWS_CLI_VERSION}

# main
FROM debian:${DEBIAN_VERSION}
ARG PYTHON_MAJOR_VERSION
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    ca-certificates \
    apt-transport-https \
    git \
    jq \
    python3 \
    gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1
COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=aws-cli /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws-cli /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws-cli /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages

# install kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && apt-get update && apt-get install -y kubectl

WORKDIR /workspace
CMD ["bash"]
