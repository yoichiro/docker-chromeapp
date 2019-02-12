FROM ubuntu:18.04

ENV NACL_SDK_ROOT=/opt/nacl_sdk/pepper_49
ENV PATH=/root/.nodebrew/current/bin:/opt/depot_tools:"$PATH"

# Install dependencies
RUN apt-get update && \
    apt-get install -y build-essential wget curl zip python libc6-i386 zlib1g-dev libssh-dev lib32z1-dev git cmake autoconf gettext libtool pkg-config

# Configure git
RUN git config --global user.email "yoichiro@eisbahn.jp" && \
    git config --global user.name "Yoichiro Tanaka"

# Install Native Client SDK
RUN cd /root && \
    wget https://storage.googleapis.com/nativeclient-mirror/nacl/nacl_sdk/nacl_sdk.zip && \
    cd /opt && \
    unzip /root/nacl_sdk.zip  && \
    cd nacl_sdk && \
    sed -i -e 's/fancy_urllib.FancyRequest(url)/fancy_urllib.FancyRequest(url.replace("https:\/\/", "http:\/\/"))/' sdk_tools/download.py && \
    ./naclsdk update || \
    sed -i -e 's/fancy_urllib.FancyRequest(url)/fancy_urllib.FancyRequest(url.replace("https:\/\/", "http:\/\/"))/' sdk_tools/download.py && \
    ./naclsdk update

# Install depot tools
RUN cd /opt && \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

# Install webports
RUN cd /opt && \
    mkdir webports && \
    cd webports && \
    gclient config --unmanaged --name=src https://chromium.googlesource.com/webports.git && \
    gclient sync --with_branch_heads && \
    cd src && \
    git checkout -b pepper_49 origin/pepper_49 && \
    gclient sync && \
    sed -i "/^TestStep/,/^}/s/^/#/g" ports/glibc-compat/build.sh && \
    sed -i "/^TestStep/,/^}/s/^/#/g" ports/openssl/build.sh && \
    sed -i "/^TestStep/,/^}/s/^/#/g" ports/zlib/build.sh && \
    sed -i "/^TestStep/,/^}/s/^/#/g" ports/nacl-spawn/build.sh && \
    sed -i "/^TestStep/,/^}/s/^/#/g" ports/jsoncpp/build.sh && \
    sed -i -e "s/tests/example/" ports/libssh2/build.sh

# Install nodebrew
RUN cd /root && \
    curl -L git.io/nodebrew | perl - setup && \
    /root/.nodebrew/current/bin/nodebrew install-binary v8.15.0 && \
    /root/.nodebrew/current/bin/nodebrew use v8.15.0

# Install tools for node
RUN root/.nodebrew/current/bin/npm install -g bower && \
    root/.nodebrew/current/bin/npm install -g grunt

# Prepare working volume
RUN mkdir /root/project

VOLUME /root/project

CMD ["/bin/bash"]
