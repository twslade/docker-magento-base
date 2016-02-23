FROM phusion/baseimage
MAINTAINER Thomas Slade <thomas@blueacorn.com>

# Install the base packages we will need
RUN apt-get update
RUN apt-get install -y \
    wget \
    htop \
    curl \
    build-essential \
    bison \
    openssl \
    git-core \
    zlib1g \
    zlib1g-dev \
    vim \
    automake \
    gcc \
    sqlite3 \
    subversion \
    autoconf \
    pkg-config \
    supervisor \
    libssl-dev \
    libxml2-dev \
    libreadline5 \
    libreadline-dev \
    libreadline-dev \
    libsqlite3-0 \
    libsqlite3-dev \
    libssl-dev \
    libsslcommon2-dev \
    libcurl4-openssl-dev \
    libbz2-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxpm-dev \
    libmcrypt-dev \
    libt1-dev \
    libltdl-dev \
    libmhash-dev \
    libmysqlclient-dev \
    mysql-client-5.6 \
    apache2 \
    apache2-mpm-prefork \
    libapache2-mod-fcgid

# Download a copy of cweiske/phpfarm repo
RUN git clone git://github.com/amacgregor/phpfarm.git /opt/phpfarm

# Copy the custom configuration files
COPY config/phpfarm/src /opt/phpfarm/src/

# Compile, then delete sources (saves space)
RUN cd /opt/phpfarm/src && \
./compile.sh 5.3.29 && \
./compile.sh 5.4.38 && \
./compile.sh 5.5.22 && \
./compile.sh 5.6.6 && \
rm -rf /opt/phpfarm/src && \
apt-get clean && \
rm -rf /var/lib/apt/lists/*

# Setup the PHPfpm services
#COPY config/etc/init /etc/init/
COPY config/phpfarm/php-5.3.29/etc/php-fpm.conf /opt/phpfarm/inst/php-5.3.29/etc/
COPY config/phpfarm/php-5.4.38/etc/php-fpm.conf /opt/phpfarm/inst/php-5.4.38/etc/
COPY config/phpfarm/php-5.5.22/etc/php-fpm.conf /opt/phpfarm/inst/php-5.5.22/etc/
COPY config/phpfarm/php-5.6.6/etc/php-fpm.conf  /opt/phpfarm/inst/php-5.6.6/etc/

## Create the run scripts
RUN mkdir -p /opt/scripts/
ADD scripts/start-apache2.sh /opt/scripts/start-apache2.sh
ADD scripts/start-phpfpm-5.3.29.sh /opt/scripts/start-phpfpm-5.3.29.sh
ADD scripts/start-phpfpm-5.4.38.sh /opt/scripts/start-phpfpm-5.4.38.sh
ADD scripts/start-phpfpm-5.5.22.sh /opt/scripts/start-phpfpm-5.5.22.sh
ADD scripts/start-phpfpm-5.6.6.sh /opt/scripts/start-phpfpm-5.6.6.sh

# Apache configuration
RUN a2enmod rewrite macro alias proxy proxy_fcgi

# Enable the configuration
COPY config/etc/apache2/conf-available /etc/apache2/conf-available
RUN a2enconf macros.conf

RUN chmod 755 /opt/scripts/*.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
CMD ["/run.sh"]
