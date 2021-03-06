# radare2 usage with retdec
# =========================
#
# Run the docker image:
# $ docker run -ti -v /home/<user>/binaries:/binaries --cap-drop=ALL r2docker:latest r2 /binaries/file

# Using debian 9 as base image.
FROM debian:9

# Label base
LABEL r2docker latest

# Radare version
ARG R2_VERSION=master
# R2pipe python version
ARG R2_PIPE_PY_VERSION=0.8.9
# R2pipe node version
ARG R2_PIPE_NPM_VERSION=2.3.2

ENV R2_VERSION ${R2_VERSION}
ENV R2_PIPE_PY_VERSION ${R2_PIPE_PY_VERSION}
ENV R2_PIPE_NPM_VERSION ${R2_PIPE_NPM_VERSION}

RUN echo -e "Building versions:\n\
  R2_VERSION=$R2_VERSION\n\
  R2_PIPE_PY_VERSION=${R2_PIPE_PY_VERSION}\n\
  R2_PIPE_NPM_VERSION=${R2_PIPE_NPM_VERSION}"

# Install all build dependencies
# Install bindings
# Build and install radare2 on master branch
RUN DEBIAN_FRONTEND=noninteractive dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y \
  perl \
  openssl \
  curl \
  gcc \
  git \
  bison \
  pkg-config \
  make \
  glib-2.0 \
  libc6:i386 \
  libncurses5:i386 \
  libstdc++6:i386 \
  gnupg2 \
  sudo && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs python-pip \
	build-essential                                     \
	cmake                                               \
	git                                                 \
	perl                                                \
	python3                                             \
	doxygen                                             \
	graphviz                                            \
	upx                                                 \
	flex                                                \
	zlib1g-dev                                          \
	autoconf                                            \
	automake                                            \
	pkg-config                                          \
	m4                                                  \
	libtool                                             \
  && \
  pip install r2pipe=="$R2_PIPE_PY_VERSION" && \
  npm install --unsafe-perm -g "r2pipe@$R2_PIPE_NPM_VERSION" && \
  git clone -b "$R2_VERSION" -q --depth 1 https://github.com/radare/radare2.git && \
  cd radare2 && \
  ./sys/install.sh && \
  make install && \
  apt-get install -y xz-utils

# Create non-root user
RUN useradd -m r2 && \
  adduser r2 sudo && \
  echo "r2:r2" | chpasswd

# Initilise base user
USER r2
WORKDIR /home/r2
ENV HOME /home/r2

# Setup r2pm
RUN r2pm init && \
  r2pm update && \
  chown -R r2:r2 /home/r2/.config

# Install retdec dependency
RUN git clone https://github.com/avast-tl/retdec && \
	cd retdec && \
	mkdir build && \
	cd build && \
	cmake .. -DCMAKE_INSTALL_PREFIX=/home/r2/retdec/retdec-install && \
	make -j$(nproc) && \
	make install

ENV PATH /home/r2/retdec/retdec-install/bin:$PATH

# Install r2dec and r2retdec plugins to be able to get better human decompiled C code of the specific assembler function
RUN r2pm init && r2pm update && r2pm -i r2dec
RUN touch .r2retdec && echo '/home/r2/retdec/retdec-install/bin/retdec-decompiler.py' >> .r2retdec
ARG flags=""
# Add parametes to retdec-decompile.py if flags is not empty
RUN r2pm -i r2retdec
RUN /bin/bash -c "flagscheck="$(echo $flags | tr -d ' ')"; if [ -n "$flagscheck" ] ; then sed -i -e 's/\`\${retDecPath} --cleanup -o \${a.tmp} -l py --select-ranges \${functionStartAddress}-\${functionEndAddress} \${binaryPath}\`;/\`\${retDecPath} --cleanup -o \${a.tmp} -l py $flags --select-ranges \${functionStartAddress}-\${functionEndAddress} \${binaryPath}\`;/g' -e 's/\`\${retDecPath} --cleanup -o \${a.tmp} --select-ranges \${functionStartAddress}-\${functionEndAddress} \${binaryPath}\`;/\`\${retDecPath} --cleanup -o \${a.tmp} $flags --select-ranges \${functionStartAddress}-\${functionEndAddress} \${binaryPath}\`;/g' /home/r2/.local/share/radare2/r2pm/git/r2retdec/r2retdec.js; fi"
