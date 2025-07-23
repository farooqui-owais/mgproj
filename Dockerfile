# Dockerfile for Magento PHP-FPM
# Use a specific PHP 8.2 version for better stability (e.g., 8.2.19, check current stable tags)
# alpine is good for small image size
FROM php:8.2-fpm-alpine

# Arguments for build-time configuration (optional, but good practice for Marketplace keys)
ARG COMPOSER_AUTH_JSON="{}"

# Set working directory early for better caching and context
WORKDIR /var/www/html

# Install system dependencies and PHP extensions required by Magento
# Group apk add and php-ext commands to minimize layers and image size
# Ensure curl is installed before adding Composer, and git for composer install
# sodium is often not required unless explicitly used by a specific module
RUN apk add --no-cache \
    bash \
    git \
    unzip \
    curl \
    icu-dev \
    libxml2-dev \
    libzip-dev \
    gd-dev \
    imagemagick-dev \
    oniguruma-dev \
    gmp-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    mysql-client \
    libsodium-dev \
    libxslt-dev \
    zlib-dev \
    libffi-dev \
    tzdata \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        ctype \
        curl \
        dom \
        exif \
        fileinfo \
        gd \
        gmp \
        iconv \
        intl \
        json \
        mbstring \
        opcache \
        pcntl \
        pdo \
        pdo_mysql \
        simplexml \
        soap \
        sockets \
        sodium \
        tokenizer \
        xsl \
        zip \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -rf /var/cache/apk/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copy your Magento source code into the image
# This step should come AFTER dependencies and Composer installation
# If your .dockerignore is good, this layer will only include necessary files
COPY . /var/www/html

# Optional: Add auth.json for Composer if using private repositories (e.g., Magento Marketplace)
# This should be done before composer install
# Pass this as a build argument: docker build --build-arg COMPOSER_AUTH_JSON="$(cat auth.json)" -t ... .
RUN if [ -n "$COMPOSER_AUTH_JSON" ] && [ "$COMPOSER_AUTH_JSON" != "{}" ]; then \
    echo "$COMPOSER_AUTH_JSON" > /root/.composer/auth.json; \
    fi

# Install Composer dependencies
# --no-dev for production images
# --optimize-autoloader is good
# --ignore-platform-reqs can be used if you know platform requirements are met outside Composer's check
# --prefer-dist for faster installs
RUN composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction
# Set appropriate permissions
# Ensure correct user and group, 'www-data' for Nginx/PHP-FPM
# Directories need write permissions for the web server user
# /var, /pub/media, /pub/static (if static files generated at runtime), /app/etc (for env.php)
# The `setfacl` method can be more robust if permissions are tricky.
# Using a specific user ID (1000) for www-data is good for consistency.
RUN usermod -u 1000 www-data && \
    chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type d -exec chmod 775 {} + && \
    find /var/www/html -type f -exec chmod 664 {} + && \
    chmod -R g+w /var/www/html/var /var/www/html/pub/media /var/www/html/pub/static /var/www/html/app/etc

# Ensure the web server user runs the application
USER www-data

# Copy the entrypoint script
# Should be copied after permissions are set (or handle permissions within entrypoint)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Entrypoint script will handle initial Magento setup
ENTRYPOINT ["docker-entrypoint.sh"]

# Expose PHP-FPM port
EXPOSE 9000

# Default command to run PHP-FPM
CMD ["php-fpm"]