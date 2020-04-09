FROM ubuntu:18.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y build-essential wget curl zip python libc6-i386 zlib1g-dev libssh-dev lib32z1-dev git cmake autoconf gettext libtool pkg-config

# Add a new user
RUN groupadd --gid 1000 yoichiro && useradd -u 1000 -g 1000 -d /home/yoichiro -m yoichiro
USER yoichiro

# Set environment variables
ENV NACL_SDK_ROOT=/home/yoichiro/nacl_sdk/pepper_49
ENV PATH=/home/yoichiro/.nodebrew/current/bin:/home/yoichiro/depot_tools:"$PATH"

WORKDIR /home/yoichiro

# Configure git
RUN git config --global user.email "yoichiro@eisbahn.jp" && \
    git config --global user.name "Yoichiro Tanaka"

# Install Native Client SDK
RUN wget https://storage.googleapis.com/nativeclient-mirror/nacl/nacl_sdk/nacl_sdk.zip && \
    unzip ./nacl_sdk.zip  && \
    cd nacl_sdk && \
    sed -i -e 's/fancy_urllib.FancyRequest(url)/fancy_urllib.FancyRequest(url.replace("https:\/\/", "http:\/\/"))/' sdk_tools/download.py && \
    ./naclsdk update || \
    sed -i -e 's/fancy_urllib.FancyRequest(url)/fancy_urllib.FancyRequest(url.replace("https:\/\/", "http:\/\/"))/' sdk_tools/download.py && \
    ./naclsdk update

WORKDIR /home/yoichiro

# Install depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

WORKDIR /home/yoichiro

# Install webports
RUN mkdir webports && \
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

WORKDIR /home/yoichiro

# Install nodebrew
RUN curl -L git.io/nodebrew | perl - setup && \
    $HOME/.nodebrew/current/bin/nodebrew install-binary v8.15.0 && \
    $HOME/.nodebrew/current/bin/nodebrew use v8.15.0

# Install tools for node
RUN $HOME/.nodebrew/current/bin/npm install -g bower && \
    $HOME/.nodebrew/current/bin/npm install -g grunt

# Prepare working volume
WORKDIR /home/yoichiro/project

VOLUME /home/yoichiro/project

CMD ["/bin/bash"]
