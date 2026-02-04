FROM php:8.3-cli

# Essential tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        nginx \
        supervisor \
        curl \
        git \
        subversion \
        git-svn \
        unzip \
        nano \
        nodejs \
        npm \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
        libicu-dev \
        libldap2-dev \
        zip \
        tree \
        tmux \
        locales \
        procps \
        gnupg2 \
        unixodbc-dev \
        build-essential \
        gpg && \
    rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    zip \
    ldap

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Microsoft SQL Server support
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys EE4D7792F748182B && \
    gpg --export EE4D7792F748182B | tee -a /usr/share/keyrings/microsoft-prod.gpg > /dev/null && \
    curl https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# Install PEAR/PECL
RUN curl -O https://pear.php.net/go-pear.phar && \
    printf "\n" | php go-pear.phar && \
    rm go-pear.phar && \
    pecl channel-update pecl.php.net

# Install SQL Server PHP extensions
RUN pecl install sqlsrv pdo_sqlsrv && \
    echo "extension=sqlsrv.so" > /usr/local/etc/php/conf.d/20-sqlsrv.ini && \
    echo "extension=pdo_sqlsrv.so" > /usr/local/etc/php/conf.d/30-pdo_sqlsrv.ini

# Install mailparse extension (optional)
ARG INSTALL_MAILPARSE
RUN if [ "$INSTALL_MAILPARSE" = "true" ] ; then \
    pecl install mailparse && \
    docker-php-ext-enable mailparse ; \
fi

# Generate locale and persist it
RUN sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

# Persist locale environment for runtime
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# copy bashrc to skel for future users
COPY .bashrc /etc/skel/.bashrc
RUN sed -i 's/\r$//' /etc/skel/.bashrc

# copy to existing user's home too
COPY .bashrc /home/${USER}/.bashrc
RUN sed -i 's/\r$//' /home/${USER}/.bashrc \
    && chown ${USER}:${USER} /home/${USER}/.bashrc

# Replace SVN placeholders with actual values
ARG SVN_BASE_URL
ARG SVN_USERNAME
RUN sed -i "s|{{SVN_REPO_URL}}|${SVN_BASE_URL}|g" /etc/skel/.bashrc \
    && sed -i "s|{{SVN_REPO_USERNAME}}|${SVN_USERNAME}|g" /etc/skel/.bashrc \
    && sed -i "s|{{SVN_REPO_URL}}|${SVN_BASE_URL}|g" /home/${USER}/.bashrc \
    && sed -i "s|{{SVN_REPO_USERNAME}}|${SVN_USERNAME}|g" /home/${USER}/.bashrc


ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}
