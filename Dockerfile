FROM jupyter/minimal-notebook
MAINTAINER eterna2 <eterna2@hotmail.com>

USER root

# Node
# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 5.1.1
RUN apt-get -y update && \
  apt-get install -y curl libzmq3-dev && \
  apt-get clean
  
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc
  
# iJavascript
RUN npm install -g ijavascript mrcluster

# install iJavascript kernel
RUN mkdir -p /opt/conda/share/jupyter/kernels/javascript
COPY kernels/nodejs.json /opt/conda/share/jupyter/kernels/javascript/kernel.json


# Python dependencies
RUN apt-get -y update && \
  apt-get install -y python-qt4 && \
  apt-get clean

# Python 2
USER jovyan

# Install Python 2 packages
RUN conda install --yes \
    'python=2.7*' \
    'ipython=4.0*' \
    && conda clean -yt

USER root