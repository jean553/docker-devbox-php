# Use a specific version of the base image
FROM phusion/baseimage:jammy-1.0.0

# Set environment variables
ENV SUDOFILE=/etc/sudoers \
    DEBIAN_FRONTEND=noninteractive

# Copy necessary files
COPY change_user_uid.sh /
COPY inventory_file /etc/ansible/hosts

# Update system, install dependencies, and set up the environment
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        sudo \
        wget \
        python3 \
        python3-dev \
        python3-pip \
        aptitude \
        libfaketime \
        libssl-dev \
        autoconf \
        libtool \
        make \
        unzip \
        software-properties-common && \
    # Set up symlinks
    ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
    ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
    ln -s /bin/rm /usr/sbin/rm && \
    ln -s /bin/tar /usr/sbin/tar && \
    # Configure SSH
    rm -f /etc/service/sshd/down && \
    echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    # Create vagrant user
    useradd --shell /bin/bash --create-home --base-dir /home \
            --user-group --groups sudo --password '' vagrant && \
    mkdir -p /home/vagrant/.ssh && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    # Configure sudo
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE} && \
    # Install specific version of cURL
    cd /tmp && rm -rf curl* && \
    wget https://curl.haxx.se/download/curl-7.88.1.zip && \
    unzip curl-7.88.1.zip && cd curl-7.88.1 && \
    ./buildconf && ./configure --with-ssl && \
    make && make install && \
    cp /usr/local/bin/curl /usr/bin/curl && \
    rm -rf /usr/lib/`uname -p`-linux-gnu/libcurl.so* && ldconfig && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP and related packages
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
        php8.2-cli \
        php8.2-common \
        php8.2-pgsql \
        php8.2-curl \
        php8.2-xml \
        php8.2-zip \
        php8.2-intl \
        php8.2-bcmath \
        php8.2-mbstring \
        php8.2-xdebug && \
    # Install Ansible
    python3 -m pip install --upgrade ansible==2.10.7 setuptools && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Set update timestamp
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp && \
    # Fix tty error
    sed -i '/tty/!s/mesg n/true/' /root/.profile

# Copy provisioning files
COPY provisioning/ /provisioning

# Run Ansible playbook
RUN ansible-playbook provisioning/site.yml -c local && \
    chown -R vagrant /home/vagrant

# Set the entrypoint and default command
ENTRYPOINT ["/change_user_uid.sh"]
CMD ["/sbin/my_init"]

# Switch to non-root user
USER vagrant

# Set working directory
WORKDIR /home/vagrant
