FROM ubuntu:xenial 
# 18.04 is too new for the cluster to run
MAINTAINER <rhancock@gmail.com>
# An Ubuntu/glibc-based version of https://github.com/utensils/docker-opengl
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# apt installs
## essential packages
RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial universe" >> /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y pkg-config
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y wget build-essential apt-transport-https xvfb

# LLVM
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb https://apt.llvm.org/xenial/ llvm-toolchain-xenial-3.9 main" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y clang-3.9 llvm-3.9 && ln -s /usr/bin/llvm-config-3.9 /usr/bin/llvm-config

RUN mkdir /tmp/downloads
WORKDIR /tmp/downloads

# build mesa
WORKDIR /tmp/downloads
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list && \
	apt-get update && apt-get build-dep -y mesa && \
    wget "https://mesa.freedesktop.org/archive/mesa-18.0.1.tar.gz" && \
    tar xfv mesa-18.0.1.tar.gz && \
    rm mesa-18.0.1.tar.gz && \
    cd mesa-18.0.1 && \
	./configure --enable-glx=gallium-xlib --with-gallium-drivers=swrast,swr --disable-dri --disable-gbm --disable-egl --enable-gallium-osmesa  --enable-llvm --prefix=/usr/local && \
    make && \
    make install

# glxgears etc for testing
RUN apt-get update && apt-get install -y mesa-utils

# Cleanup
RUN apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y
RUN rm -rf /tmp/downloads
RUN ldconfig

# Setup our environment variables.
ENV XVFB_WHD="1920x1080x24"\
    LIBGL_ALWAYS_SOFTWARE="1" \
    GALLIUM_DRIVER="llvmpipe" \
    LP_NO_RAST="false" \
    LP_DEBUG="" \
    LP_PERF="" \
    LP_NUM_THREADS=""

# Singularity environment setup

RUN mkdir /usr/local/app
COPY ./xrun.sh /usr/local/app/xrun.sh

RUN /usr/bin/env |sed  '/^HOME/d' | sed '/^HOSTNAME/d' | sed  '/^USER/d' | sed '/^PWD/d' > /environment && \
	chmod 755 /environment
ENTRYPOINT ["/usr/local/app/xrun.sh"]
