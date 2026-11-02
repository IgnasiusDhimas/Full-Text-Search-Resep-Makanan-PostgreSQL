# Gunakan image PHP resmi dengan Apache
FROM php:8.2-apache

# Install ekstensi PostgreSQL (pgsql & pdo_pgsql)
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pgsql pdo_pgsql

# Set folder kerja
WORKDIR /var/www/html

# Copy semua file PHP ke dalam container
COPY . /var/www/html/

# Expose port 80 untuk Apache
EXPOSE 80