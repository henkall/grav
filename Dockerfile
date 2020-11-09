FROM nginx:1.11.9

# Desired version of grav
ARG GRAV_VERSION=1.6.28

# Install dependencies for php
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 \
    && apt-get update \
    && apt install -y sudo wget vim unzip ca-certificates apt-transport-https \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add - \
    && echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list

# Install dependencies
RUN apt-get update \
    && apt-get install -y php7.2 php7.2-curl php7.2-gd php-pclzip php7.2-fpm
ADD https://github.com/krallin/tini/releases/download/v0.13.2/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini

# Set user to www-data
RUN mkdir -p /var/www && chown www-data:www-data /var/www
USER www-data

# Install grav
WORKDIR /var/www
RUN wget https://github.com/getgrav/grav/releases/download/$GRAV_VERSION/grav-admin-v$GRAV_VERSION.zip && \
    unzip grav-admin-v$GRAV_VERSION.zip && \
    rm grav-admin-v$GRAV_VERSION.zip && \
    cd grav-admin && \
    bin/gpm install -f -y admin

# Return to root user
USER root

# Install Acmetool Let's Encrypt client
RUN echo 'deb http://ppa.launchpad.net/hlandau/rhea/ubuntu xenial main' > /etc/apt/sources.list.d/rhea.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9862409EF124EC763B84972FF5AC9651EDB58DFA \
    && apt-get update \
    && apt-get install acmetool

# Configure nginx with grav
WORKDIR grav-admin
RUN cd webserver-configs && \
    sed -i 's/root \/home\/USER\/www\/html/root \/var\/www\/grav-admin/g' nginx.conf && \
    cp nginx.conf /etc/nginx/conf.d/default.conf

# Set the file permissions
RUN usermod -aG www-data nginx

# Run startup script
ADD resources /
ENTRYPOINT [ "/usr/local/bin/tini", "--", "/usr/local/bin/startup.sh" ]
