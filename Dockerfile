# Dockerfile for Magento PHP-FPM
FROM php:8.2-fpm-alpine

# Install bash (if not already present)
RUN apt-get update && apt-get install -y bash --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Install system dependencies and PHP extensions required by Magento
RUN apk add --no-cache \
    nginx \
    mysql-client \
    git \
    unzip \
    icu-dev \
    libxml2-dev \
    libzip-dev \
    gd-dev \
    imagemagick-dev \
    curl-dev \
    gmp-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    oniguruma-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    soap \
    sockets \
    bcmath \
    gd \
    intl \
    zip \
    gmp \
    exif \
    pcntl \
    opcache && \
    rm -rf /var/cache/apk/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

# Copy your Magento source code into the image
# Assuming your Dockerfile is at the root of your Magento project
COPY . /var/www/html

# Install Composer dependencies
RUN composer install  --optimize-autoloader

# Set appropriate permissions (adjust user/group IDs if needed for your environment)
RUN usermod -u 1000 www-data && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R u=rwX,g=rwX,o=rX /var/www/html/var /var/www/html/pub/media /var/www/html/pub/static /var/www/html/app/etc

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Expose PHP-FPM port
EXPOSE 9000

CMD ["php-fpm"]