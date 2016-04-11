FROM phusion/baseimage
MAINTAINER Thomas Slade <thomas@blueacorn.com>

RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

RUN apt-get update
RUN add-apt-repository ppa:ondrej/php5-5.6
RUN apt-get install -y \
    wget \
    libicu-dev \
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
    libxslt1-dev \
    mysql-client-5.6 \
    apache2 \
    apache2-mpm-prefork \
    php5-cli \
    php5-curl \
    php5-intl \
    php5-xsl \
    libapache2-mod-fcgid

RUN apt-get install -y php5-gd php5-mcrypt php5-mysql

RUN ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini

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

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Box
RUN curl -LSs https://box-project.github.io/box2/installer.php | php && mv box.phar /usr/local/bin/

# Install N98
RUN wget https://files.magerun.net/n98-magerun.phar && chmod +x ./n98-magerun.phar && mv ./n98-magerun.phar /usr/local/bin/

# Install Modman
RUN curl -Lfo /usr/bin/modman \
  https://raw.githubusercontent.com/colinmollenhour/modman/master/modman \
  && chmod +x /usr/bin/modman

# Get copy of custom n98-magerun.yaml
RUN wget https://raw.githubusercontent.com/BlueAcornInc/bootstrap/master/tools/n98-magerun/n98-magerun.yaml?token=ABU8AwUtIJ4lKuhs2p52f0vq3Kywlxx5ks5XERxvwA%3D%3D -O n98-magerun.yaml \
    && mv n98-magerun.yaml /etc/

RUN echo "memory_limit = 1024M" >> /etc/php5/cli/php.ini

RUN chmod 755 /opt/scripts/*.sh

ADD ./id_rsa /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts && ssh-keyscan github.com >> /root/.ssh/known_hosts

# Xdebug for 5.6.6
RUN wget http://xdebug.org/files/xdebug-2.4.0rc4.tgz \
    && tar -xvf xdebug-2.4.0rc4.tgz \
    && cd /xdebug-2.4.0RC4 \
    && /opt/phpfarm/inst/bin/phpize-5.6.6 \
    && ./configure --with-php-config=/opt/phpfarm/inst/bin/php-config-5.6.6 \
    && make \
    && make install \
    && cp modules/xdebug.so /opt/phpfarm/inst/php-5.6.6/lib/php/20131226 \
    && echo "zend_extension = /opt/phpfarm/inst/php-5.6.6/lib/php/20131226/xdebug.so" >> /opt/phpfarm/inst/php-5.6.6/etc/php.ini \
    && echo "xdebug.remote_enable=on" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_autostart=off" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_port=9000" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_connect_back=On" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_handler=dbgp" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && rm -rf /xdebug-2.4.0RC4

# Xdebug for 5.5.22
RUN tar -xvf xdebug-2.4.0rc4.tgz \
    && cd /xdebug-2.4.0RC4 \
    && /opt/phpfarm/inst/bin/phpize-5.5.22 \
    && ./configure --with-php-config=/opt/phpfarm/inst/bin/php-config-5.5.22 \
    && make \
    && make install \
    && cp modules/xdebug.so /opt/phpfarm/inst/php-5.5.22/lib/php/20121212 \
    && echo "zend_extension = /opt/phpfarm/inst/php-5.5.22/lib/php/20121212/xdebug.so" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_enable=on" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_autostart=off" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_port=9000" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_connect_back=On" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_handler=dbgp" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && rm -rf /xdebug-2.4.0RC4

# Xdebug for 5.4.38
RUN tar -xvf xdebug-2.4.0rc4.tgz \
    && cd /xdebug-2.4.0RC4 \
    && /opt/phpfarm/inst/bin/phpize-5.4.38 \
    && ./configure --with-php-config=/opt/phpfarm/inst/bin/php-config-5.4.38 \
    && make \
    && make install \
    && cp modules/xdebug.so /opt/phpfarm/inst/php-5.4.38/lib/php/20100525 \
    && echo "zend_extension = /opt/phpfarm/inst/php-5.4.38/lib/php/20100525/xdebug.so" >> /opt/phpfarm/inst/php-5.4.38/etc/php.ini \
    && echo "xdebug.remote_enable=on" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_autostart=off" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_port=9000" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_connect_back=On" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && echo "xdebug.remote_handler=dbgp" >> /opt/phpfarm/inst/php-5.5.22/etc/php.ini \
    && rm -rf /xdebug-2.4.0RC4

RUN wget https://pecl.php.net/get/intl-3.0.0.tgz \
    && tar -xvf intl-3.0.0.tgz \
    && cd /intl-3.0.0 \
    && /opt/phpfarm/inst/bin/phpize-5.6.6 \
    && ./configure --with-php-config=/opt/phpfarm/inst/bin/php-config-5.6.6 \
    && make \
    && make install \
    && echo "extension=intl.so" >> /opt/phpfarm/inst/php-5.6.6/etc/php.ini \
    && echo "always_populate_raw_post_data = -1"  >> /opt/phpfarm/inst/php-5.6.6/etc/php.ini \
    && echo "extension=/usr/lib/php5/20131226/xsl.so" >> /opt/phpfarm/inst/php-5.6.6/etc/php.ini \
    && rm -rf /intl-3.0.0


RUN apt-get update
RUN apt-get install -y php5

ADD run.sh /run.sh
RUN chmod 755 /*.sh
CMD ["/run.sh"]
