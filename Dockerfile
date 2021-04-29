FROM ubuntu:20.04 AS builder

ENV LANG=C.UTF-8

ARG ROOT_BRANCH=v6-24-00-patches
ARG ROOT_REPO=root-project/root

# Install requirements
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        # Building
        dpkg-dev \
        cmake \
        g++ \
        gcc \
        binutils \
        git \
        libx11-dev \
        libxpm-dev \
        libxft-dev \
        libxext-dev \
        python \
        libssl-dev \
        # Download
        unzip \
        wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    wget -q "https://api.github.com/repos/${ROOT_REPO}/commits?sha=${ROOT_BRANCH}&per_page=1" -O - && \
    wget --progress=dot:giga https://github.com/${ROOT_REPO}/archive/refs/heads/${ROOT_BRANCH}.zip && \
    unzip ${ROOT_BRANCH}.zip && \
    rm ${ROOT_BRANCH}.zip && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/opt/root/ ../root-* -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make install -j$(nproc)

FROM ubuntu:20.04

COPY --from=builder /opt/root/ /opt/root/
COPY packages packages

RUN apt-get update -qq && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    apt-get -y install $(cat packages) wget && \
    rm -rf /var/lib/apt/lists/* && \
    echo /opt/root/lib >> /etc/ld.so.conf && \
    ldconfig

ENV ROOTSYS /opt/root
ENV PATH $ROOTSYS/bin:$PATH
ENV PYTHONPATH $ROOTSYS/lib:$PYTHONPATH
ENV CLING_STANDARD_PCH none

CMD ["root", "-b"]
