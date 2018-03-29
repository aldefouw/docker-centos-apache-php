# Supported tags and respective `Dockerfile` links

-	[`latest`,`php71`] Centos 7 + Apache 2.4 + PHP 7.1
-   [`php56`,`php70`] Centos 7 + Apache 2.2 + PHP 7.0
-   [`php53`] Centos 6.7 + Apache 2.2 + PHP 5.3

# Info
Based on official [centos] (https://hub.docker.com/_/centos/) images with addition of:

- Apache
- PHP
- PDO
- MySQL
- DB2 (not in php71 image)
- Mbstring
- Soap
- GD
- XML
- APCu
- Kafka  (not in php71 image)
- ImageMagick

# Run
Run this image:

```console
$ docker run --name centos-apache-php \
	-d naqoda/centos-apache-php:latest
```