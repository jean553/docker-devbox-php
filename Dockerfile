# Re-use the phusion baseimage which runs an SSH server etc
FROM phusion/baseimage:resolute

# Some definitions
ENV SUDOFILE /etc/sudoers
ENV DEBIAN_FRONTEND noninteractive

COPY change_user_uid.sh /
COPY inventory_file  /etc/ansible/hosts


# Note: we chain all the command in One RUN, so that docker create only one layer
RUN \
    ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
    ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
    ln -s /bin/rm /usr/sbin/rm && \
    ln -s /bin/tar /usr/sbin/tar  && \
    # we permit sshd to be started
    rm -f /etc/service/sshd/down && \
    # we activate empty password with ssh (to simplify login \
    # as it's only a dev machine, it will never be used in production (right?) \
    echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    # we create a user vagrant (so that Vagrant will be happy)
    # without password
    useradd \
        --shell /bin/bash \
        --create-home --base-dir /home \
        --user-group \
        --groups sudo \
        --password '' \
        vagrant && \
    mkdir -p /home/vagrant/.ssh && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    # Update apt-cache, so that stuff can be installed \
    # Install python (otherwise ansible will not work) \
    # Install aptitude, since ansible needs it (only apt-get is installed) \
    apt-get -y update && \
    apt-get -y install sudo wget python3 python3-dev python3-pip aptitude libfaketime libssl-dev autoconf libtool make unzip && \
    apt-get -y upgrade && \
    apt remove -y curl && apt purge curl && \
    # Install cURL version 7.88.1 as it's not compatible with the latest version
    # of OpenSSL. See: https://stackoverflow.com/a/75867650
    cd /tmp && rm -rf curl* && \
    wget https://curl.haxx.se/download/curl-7.88.1.zip && \
    unzip curl-7.88.1.zip && cd curl-7.88.1 && \
    ./buildconf && ./configure --with-ssl && \
    make && make install && \
    cp /usr/local/bin/curl /usr/bin/curl && \
    # Fix the LDD link issue: https://github.com/curl/curl/issues/4448
    # We do this because removing the old cURL version did not remove its libraries
    # and the new cURL version is first loading these one instead of the new ones
    rm -rf /usr/lib/`uname -p`-linux-gnu/libcurl.so* && ldconfig && \
    # Enable password-less sudo for all user (including the 'vagrant' user) \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE}

RUN apt update && \
    apt install -y \
        unzip \
        php8.5-cli \
        php8.5-common \
        php8.5-pgsql \
        php8.5-curl \
        php8.5-xml \
        php8.5-zip \
        php8.5-intl \
        php8.5-bcmath \
        php8.5-mbstring \
        php8.5-xdebug \
    && \
    apt clean

# install ansible
# we use option "--break-system-packages" to allow system-wide installation,
# working around the restriction of pip to install python packages into virtual environment,
# this should not be done in prod, but this container is simply a dev container, no problem doing that...
RUN python3 -m pip install --upgrade ansible setuptools --break-system-packages && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY provisioning/ /provisioning
RUN \
    # run ansible
    ansible-playbook provisioning/site.yml -c local && \
    chown -R vagrant /home/vagrant

# install claudecode
USER ubuntu
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/claude.sh && \
    chmod u+x /tmp/claude.sh && \
    ./tmp/claude.sh
USER root

# clean
RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# on ubuntu "resolute" container, user with UID 1000 is "ubuntu"
# and most of the time, user UID on the host will be 1000 as well;
# so when creating the "vagrant" user, it takes the UID 1001 as 1000 is already used;
#
# when running "vagrant up" later, we prefer connect to the container with UID 1000 (ubuntu),
# so that we directly have ownership and modification rights on the volume mounted files,
# this requires to disable password on "ubuntu" user
RUN passwd -d ubuntu

ENTRYPOINT /change_user_uid.sh
CMD ["/sbin/my_init"]
