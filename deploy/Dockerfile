# Use Ubuntu 20 image
FROM ubuntu:20.04

LABEL maintainer="Jose Cisneros <joseacisnerosm@gmail.com>"

# Non Intercative Env Variable
ENV DEBIAN_FRONTEND=noninteractive 

# Init repo directoy
RUN mkdir /corticalThickness
COPY . /corticalThickness/
WORKDIR /corticalThickness/

# Install os dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    nano \
    git \
    wget \
    unzip \
    autoconf \
    libtool \
    libssl-dev \
    libffi-dev \
    netcdf-bin \
    libnetcdf-dev \
    perl \
    libhdf5-dev \
    libminc-dev \
    minc-tools \
    libgetopt-tabular-perl \
    python3 \
    python3-venv \
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN rm -rf /corticalThickness/bin/pyenv && pip install virtualenv
RUN virtualenv -p python3 /corticalThickness/bin/pyenv
RUN /bin/bash -c 'source /corticalThickness/bin/pyenv/bin/activate;pip3 install -r /corticalThickness/bin/requirements.txt'

# Install Perl dependencies
RUN cd /tmp && git clone https://github.com/BIC-MNI/mni-perllib.git
RUN cd /tmp/mni-perllib \
    && (echo "/usr/local/bic/share/mni-models" && cat) | perl Makefile.PL
RUN cd /tmp/mni-perllib \ 
    && make \
    && make install 

ENTRYPOINT ["python3","/corticalThickness/code/corticalThickness.py"]
