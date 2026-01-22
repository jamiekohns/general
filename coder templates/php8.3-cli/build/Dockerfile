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
        procps && \
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

# copy to skel for future users
COPY .bashrc /etc/skel/.bashrc
RUN sed -i 's/\r$//' /etc/skel/.bashrc

# copy to existing user's home too
COPY .bashrc /home/${USER}/.bashrc
RUN sed -i 's/\r$//' /home/${USER}/.bashrc \
    && chown ${USER}:${USER} /home/${USER}/.bashrc

# Generate locale and persist it
RUN sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

# Persist locale environment for runtime
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Copy runapp.sh - replace this with a bashrc function to curl fetch from repo
COPY runapp.sh /home/${USER}/runapp.sh
RUN sed -i 's/\r$//' /home/${USER}/runapp.sh
RUN chmod +x /home/${USER}/runapp.sh \
    && ln -sf /home/${USER}/runapp.sh /usr/bin/runapp

ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

RUN mkdir -p /home/${USER}/projects