# Supported tags and respective `Dockerfile` links

-	[`latest`] Centos 7 + Apache 2.4 + PHP 5.6
-   [`beta`] Centos 7 + Apache 2.2 + PHP 7.0
-   [`centos6-apache22-php53`] Centos 6.7 + Apache 2.2 + PHP 5.3

# Info
Based on official [centos] (https://hub.docker.com/_/centos/) images with addition of:

- Apache
- PHP
- PDO
- MySQL
- DB2
- Mbstring
- Soap
- GD
- XML
- APCu
- Kafka
- wkhtmltopdf

# Run
Run this image:

```console
$ docker run --name centos-apache-php \
	-d naqoda/centos-apache-php:latest
```