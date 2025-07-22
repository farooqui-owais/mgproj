FROM webdevops/php-nginx-dev:8.1
LABEL maintainer="Owais farooquiowais70@gmail.com"

# Install required PHP extensions if not already present in the base image
RUN apt-get update && apt-get install -y \
    git \
    libxml2-dev \
    libzip-dev \
    # Add other extensions as needed, e.g., gd, intl, xsl, soap, bcmath, exif, opcache
    && docker-php-ext-install -j$(nproc) soap pdo_mysql opcache \
    && rm -rf /var/lib/apt/lists/*

# Copy Magento application files into the container
# This is usually done via a Kubernetes Persistent Volume Claim, so this part
# might be less critical for the image itself if you mount your code.
# However, for a production-ready image, you'd bake the code in.
# For local dev, mounting is often preferred.
# COPY . /var/www/html/

WORKDIR /var/www/html

# Set appropriate permissions (adjust as per your needs, but 777 is generally not recommended for production)
RUN usermod -u 1000 www-data && chown -R www-data:www-data /var/www/html

# You might want to run composer install here if you're baking the code into the image
# RUN composer install --no-dev --prefer-dist --optimize-autoloader