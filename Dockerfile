# =============================================================================
# naqoda/centos-apache-php
#
# CentOS-7, Apache 2.2, PHP 5.5, Ioncube, MYSQL, DB2
# 
# =============================================================================
FROM centos:centos7

MAINTAINER Erik Bogaerts <ebo@naqoda.com>

# -----------------------------------------------------------------------------
# Import the RPM GPG keys for Repositories
# -----------------------------------------------------------------------------
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#RUN yum -y update

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network

# -----------------------------------------------------------------------------
# Purge
# -----------------------------------------------------------------------------
#RUN rm -rf /etc/ld.so.cache \ 
#	; rm -rf /sbin/sln \
#	; rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,gnome/help,cracklib,il8n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
#	; rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
#	; > /etc/sysconfig/i18n

# -----------------------------------------------------------------------------
# Apache
# -----------------------------------------------------------------------------
RUN	yum --setopt=tsflags=nodocs -y install \
	unzip \
	httpd \
	mod_ssl \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# PHP
# -----------------------------------------------------------------------------
RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

RUN	yum --setopt=tsflags=nodocs -y install \
	php56w \
	php56w-cli \
	php56w-mysql \
	php56w-pdo \
	php56w-mbstring \
	php56w-soap \
	php56w-gd \
	php56w-xml \
	php56w-pecl-apcu \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Install DB2 PDO driver
# -----------------------------------------------------------------------------
ENV DB2EXPRESSC_URL https://s3-ap-southeast-1.amazonaws.com/naqoda/downloads/ibm_data_server_driver_package_linuxx64_v10.5.tar.gz

RUN mkdir /opt/ibm \
    && curl -fSLo /opt/ibm/expc.tar.gz $DB2EXPRESSC_URL  \
    && cd /opt/ibm && tar xf expc.tar.gz \
    && rm /opt/ibm/expc.tar.gz

ENV IBM_DB_HOME /opt/ibm/dsdriver

RUN cp $IBM_DB_HOME/php_driver/linuxamd64/php64/ibm_db2_5.3.6_nts.so /usr/lib64/php/modules/ibm_db2.so \
	&& cp $IBM_DB_HOME/php_driver/linuxamd64/php64/pdo_ibm_5.3.6_nts.so /usr/lib64/php/modules/pdo_ibm.so

RUN cd /opt/ibm/dsdriver/odbc_cli_driver/linuxamd64 \
    && tar xf ibm_data_server_driver_for_odbc_cli.tar.gz

ENV LD_LIBRARY_PATH /opt/ibm/dsdriver/odbc_cli_driver/linuxamd64/clidriver/lib

COPY modules/ibm_db2.so /usr/lib64/php/modules/ibm_db2.so

COPY modules/pdo_ibm.so /usr/lib64/php/modules/pdo_ibm.so
	
RUN echo 'extension=ibm_db2.so' > /etc/php.d/pdo_db2.ini \
	&& echo 'extension=pdo_ibm.so' >> /etc/php.d/pdo_db2.ini

# -----------------------------------------------------------------------------
# Global Apache configuration changes
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^ServerSignature On$~ServerSignature Off~g' \
	-e 's~^ServerTokens OS$~ServerTokens Prod~g' \
	-e 's~^DirectoryIndex \(.*\)$~DirectoryIndex \1 index.php~g' \
	-e 's~^NameVirtualHost \(.*\)$~#NameVirtualHost \1~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable Apache directory indexes
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^IndexOptions \(.*\)$~#IndexOptions \1~g' \
	-e 's~^IndexIgnore \(.*\)$~#IndexIgnore \1~g' \
	-e 's~^AddIconByEncoding \(.*\)$~#AddIconByEncoding \1~g' \
	-e 's~^AddIconByType \(.*\)$~#AddIconByType \1~g' \
	-e 's~^AddIcon \(.*\)$~#AddIcon \1~g' \
	-e 's~^DefaultIcon \(.*\)$~#DefaultIcon \1~g' \
	-e 's~^ReadmeName \(.*\)$~#ReadmeName \1~g' \
	-e 's~^HeaderName \(.*\)$~#HeaderName \1~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable Apache language based content negotiation
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^LanguagePriority \(.*\)$~#LanguagePriority \1~g' \
	-e 's~^ForceLanguagePriority \(.*\)$~#ForceLanguagePriority \1~g' \
	-e 's~^AddLanguage \(.*\)$~#AddLanguage \1~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable all Apache modules and enable the minimum
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^\(LoadModule .*\)$~#\1~g' \
	-e 's~^\(#LoadModule version_module modules/mod_version.so\)$~\1\n#LoadModule reqtimeout_module modules/mod_reqtimeout.so~g' \
	-e 's~^#LoadModule mime_module ~LoadModule mime_module ~g' \
	-e 's~^#LoadModule log_config_module ~LoadModule log_config_module ~g' \
	-e 's~^#LoadModule setenvif_module ~LoadModule setenvif_module ~g' \
	-e 's~^#LoadModule status_module ~LoadModule status_module ~g' \
	-e 's~^#LoadModule authz_host_module ~LoadModule authz_host_module ~g' \
	-e 's~^#LoadModule dir_module ~LoadModule dir_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	-e 's~^#LoadModule rewrite_module ~LoadModule rewrite_module ~g' \
	-e 's~^#LoadModule expires_module ~LoadModule expires_module ~g' \
	-e 's~^#LoadModule deflate_module ~LoadModule deflate_module ~g' \
	-e 's~^#LoadModule headers_module ~LoadModule headers_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Enable ServerStatus access via /_httpdstatus to local client
# -----------------------------------------------------------------------------
RUN sed -i \
	-e '/#<Location \/server-status>/,/#<\/Location>/ s~^#~~' \
	-e '/<Location \/server-status>/,/<\/Location>/ s~Allow from .example.com~Allow from localhost 127.0.0.1~' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable the default SSL Virtual Host
# -----------------------------------------------------------------------------
RUN sed -i \
	-e '/<VirtualHost _default_:443>/,/#<\/VirtualHost>/ s~^~#~' \
	/etc/httpd/conf.d/ssl.conf

# -----------------------------------------------------------------------------
# Apache tuning
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^StartServers \(.*\)$~StartServers 3~g' \
	-e 's~^MinSpareServers \(.*\)$~MinSpareServers 3~g' \
	-e 's~^MaxSpareServers \(.*\)$~MaxSpareServers 3~g' \
	-e 's~^ServerLimit \(.*\)$~ServerLimit 10~g' \
	-e 's~^MaxClients \(.*\)$~MaxClients 10~g' \
	-e 's~^MaxRequestsPerChild \(.*\)$~MaxRequestsPerChild 1000~g' \
	/etc/httpd/conf/httpd.conf
	
# -----------------------------------------------------------------------------
# Limit process for the application user
# -----------------------------------------------------------------------------
RUN { \
		echo ''; \
		echo $'apache\tsoft\tnproc\t30'; \
		echo $'apache\thard\tnproc\t50'; \
		echo $'app-www\tsoft\tnproc\t30'; \
		echo $'app-www\thard\tnproc\t50'; \
	} >> /etc/security/limits.conf

# -----------------------------------------------------------------------------
# Global PHP configuration changes
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^;date.timezone =$~date.timezone = UTC~g' \
	-e 's~^;user_ini.filename =$~user_ini.filename =~g' \
	/etc/php.ini

ADD ioncube/ioncube_loader_lin_5.6.so /usr/lib64/php/modules/ioncube_loader_lin_5.6.so
RUN echo '[Ioncube]' >> /etc/php.ini
RUN echo 'zend_extension = /usr/lib64/php/modules/ioncube_loader_lin_5.6.so' >> /etc/php.ini 

# -----------------------------------------------------------------------------
# Add default service users
# -----------------------------------------------------------------------------
RUN useradd -u 501 -d /var/www/app -m app \
	&& useradd -u 502 -d /var/www/app -M -s /sbin/nologin -G app app-www \
	&& usermod -a -G app-www app \
	&& usermod -a -G app-www apache

# -----------------------------------------------------------------------------
# Add a symbolic link to the app users home within the home directory &
# Create the initial directory structure
# -----------------------------------------------------------------------------
RUN ln -s /var/www/app /home/app \
	&& mkdir -p /var/www/app/{public_html,var/{log,session}}

# -----------------------------------------------------------------------------
# Virtual hosts configuration
# -----------------------------------------------------------------------------
ADD etc/httpd/conf.d/ /etc/httpd/conf.d

# -----------------------------------------------------------------------------
# Create the SSL VirtualHosts configuration file
# -----------------------------------------------------------------------------
#RUN sed -i \
#	-e 's~^<VirtualHost \*:80>$~<VirtualHost \*:443>~g' \
#	-e '/<IfModule mod_ssl.c>/,/<\/IfModule>/ s~^#~~' \
#	/var/www/app/vhost-ssl.conf

# -----------------------------------------------------------------------------
# Set permissions (app:app-www)
# -----------------------------------------------------------------------------
RUN chown -R app:app-www /var/www/app \
	&& chmod 775 /var/www/app \
	&& chmod g+w /var/www/app/var/session

# -----------------------------------------------------------------------------
# Set default environment variables used to identify the service container
# -----------------------------------------------------------------------------
ENV SERVICE_UNIT_APP_GROUP app-1
ENV SERVICE_UNIT_LOCAL_ID 1
ENV SERVICE_UNIT_INSTANCE 1

# -----------------------------------------------------------------------------
# Set default environment variables used to configure the service container
# -----------------------------------------------------------------------------
ENV APACHE_SERVER_ALIAS ""
ENV APACHE_SERVER_NAME app-1.local
ENV APP_HOME_DIR /var/www/app
ENV DATE_TIMEZONE UTC
ENV HTTPD /usr/sbin/httpd
ENV SERVICE_USER app
ENV SERVICE_USER_GROUP app-www
ENV SERVICE_USER_PASSWORD ""
ENV SUEXECUSERGROUP false
ENV TERM xterm

EXPOSE 80 443

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD index.php /var/www/app/public_html/index.php

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]