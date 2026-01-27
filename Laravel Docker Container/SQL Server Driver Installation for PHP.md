# SQL Server Driver Installation for PHP on Debian

This document outlines the commands used to successfully install Microsoft SQL Server support for PHP 8.2 on Debian.

## Components Installed
- ✅ Microsoft ODBC Driver 18 for SQL Server
- ✅ PHP sqlsrv extension
- ✅ PHP pdo_sqlsrv extension

## Installation Steps

### 1. Install GPG Tools
```bash
sudo apt-get update
sudo apt-get install -y gnupg2
```

### 2. Add Microsoft GPG Keys
```bash
# Download and add the Microsoft package signing key
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# Import the additional GPG key
sudo gpg --keyserver keyserver.ubuntu.com --recv-keys EE4D7792F748182B
sudo gpg --export EE4D7792F748182B | sudo tee -a /usr/share/keyrings/microsoft-prod.gpg > /dev/null
```

### 3. Add Microsoft SQL Server Repository
```bash
curl https://packages.microsoft.com/config/debian/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
```

### 4. Install Microsoft ODBC Driver and Build Tools
```bash
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev build-essential
```

### 5. Install PEAR/PECL
```bash
# Download and install PEAR (which includes PECL)
curl -O https://pear.php.net/go-pear.phar
sudo php go-pear.phar
# Press Enter to accept defaults during installation

# Update PECL channel
sudo pecl channel-update pecl.php.net
```

### 6. Install SQL Server PHP Extensions
```bash
sudo pecl install sqlsrv pdo_sqlsrv
```

### 7. Enable PHP Extensions
```bash
# Create configuration files to load the extensions
sudo bash -c 'echo "extension=sqlsrv.so" > /usr/local/etc/php/conf.d/20-sqlsrv.ini'
sudo bash -c 'echo "extension=pdo_sqlsrv.so" > /usr/local/etc/php/conf.d/30-pdo_sqlsrv.ini'
```

### 8. Verify Installation
```bash
# Check that extensions are loaded
php -m | grep -i sqlsrv

# Should output:
# pdo_sqlsrv
# sqlsrv
```

## Configuration

The Laravel `config/database.php` file can now use the `sqlsrv` driver with PDO constants:

```php
'sqlsrv' => [
    'driver' => 'sqlsrv',
    'url' => env('DB_URL'),
    'host' => env('DB_HOST', 'localhost'),
    'port' => env('DB_PORT', '1433'),
    'database' => env('DB_DATABASE', 'laravel'),
    'username' => env('DB_USERNAME', 'root'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => env('DB_CHARSET', 'utf8'),
    'prefix' => '',
    'prefix_indexes' => true,
    'options' => [
        PDO::SQLSRV_ATTR_ENCODING => PDO::SQLSRV_ENCODING_UTF8,
    ],
],
```

## Notes

- The installation was performed on Debian Trixie (13)
- PHP version: 8.2.30
- ODBC Driver version: 18.6.1.1
- SQL Server PHP extensions version: 5.12.0
