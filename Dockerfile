FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive 

# Essential tools
RUN apt-get update && apt-get -y install sudo gcc build-essential vim git gtkwave

# Used for LLVM
RUN apt-get -y install clang lldb lld libedit-dev gnat libz-dev

# Used for iverilog
RUN apt-get -y install bison flex gperf readline-common libncurses5-dev autoconf

# Used for yosys
RUN apt-get -y install build-essential clang bison flex libreadline-dev gawk tcl-dev \
                       libffi-dev git graphviz xdot pkg-config python3 libboost-system-dev \
                       libboost-python-dev libboost-filesystem-dev zlib1g-dev

# Used for netlistsvg
RUN apt-get -y install nodejs npm

# Used for openFPGALoader
RUN apt-get -y install libftdi1-2 libftdi1-dev libhidapi-hidraw0 libhidapi-dev libudev-dev \
                       zlib1g-dev cmake pkg-config make g++ libgpiod-dev gpiod

# Used for apicula
RUN apt-get -y install python3-pip

# Used for nextpnr
RUN apt-get -y install libboost-all-dev libeigen3-dev

# Octave related packages
RUN apt-get -y install octave liboctave-dev

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up the build environment in CMD. Use bash as an alias for sh.
RUN rm /bin/sh && ln -s bash /bin/sh

# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The host_uid and group_uid are passed to the docker build
# command with the --build-arg option. The docker image creates a group with host_gid and a user
# with host_uid and adds the user to the group. Do not attribute a value to ARGs here!
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ENV USER_NAME fpga
ARG host_uid
ARG host_gid
RUN groupadd -g $host_gid $USER_NAME && \
    useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# The user "fpga" will have root privileges and its password is "fpga"
RUN echo "${USER_NAME}:${USER_NAME}" | chpasswd && adduser ${USER_NAME} sudo

USER $USER_NAME
WORKDIR /home/$USER_NAME/workspace
