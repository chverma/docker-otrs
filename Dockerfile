FROM ubuntu:16.04
MAINTAINER chverma <chverma.com>

# Definitions
ENV OTRS_VERSION=3_3

RUN apt-get update && \
    apt-get install -y supervisor \
    apt-utils \
    libterm-readline-perl-perl && \
    apt-get install -y locales && \
    locale-gen es_ES.UTF-8
ENV LANG es_ES.UTF-8
ENV LANGUAGE es_ES:es
ENV LC_ALL es_ES.UTF-8

RUN apt-get install -y apache2 git bash-completion cron sendmail curl vim wget mysql-client

#CREATE OTRS USER
RUN useradd -d /opt/otrs -c 'OTRS user' otrs && \
    usermod -a -G www-data otrs && \
    usermod -a -G otrs www-data

RUN apt-get install libdigest-md5-perl

RUN cd /opt && \
    wget https://ftp.otrs.org/pub/otrs/otrs-3.3.20.tar.gz && \
    tar -xzvf otrs-3.3.20.tar.gz && \
    mv otrs-3.3.20 otrs

RUN ls -l /opt/ && cd /opt/otrs/ && \
    cp Kernel/Config.pm.dist Kernel/Config.pm && \
    cp Kernel/Config/GenericAgent.pm.dist Kernel/Config/GenericAgent.pm

# perl modules
RUN apt-get install -y  libarchive-zip-perl \
                        libcrypt-eksblowfish-perl \
                        libcrypt-ssleay-perl \
                        libtimedate-perl \
                        libdatetime-perl \
                        libdbi-perl \
                        libdbd-mysql-perl \
                        libdbd-odbc-perl \
                        libdbd-pg-perl \
                        libencode-hanextra-perl \
                        libio-socket-ssl-perl \
                        libjson-xs-perl \
                        libmail-imapclient-perl \
                        libio-socket-ssl-perl \
                        libauthen-sasl-perl \
                        libauthen-ntlm-perl \
                        libapache2-mod-perl2 \
                        libnet-dns-perl \
                        libnet-ldap-perl \
                        libtemplate-perl \
                        libtemplate-perl \
                        libtext-csv-xs-perl \
                        libxml-libxml-perl \
                        libxml-libxslt-perl \
                        libxml-parser-perl \
                        libyaml-libyaml-perl \
			libcgi-application-basic-plugin-bundle-perl

#apt-get install gcc

#perl -e shell -MCPAN
#$ install CGI
#perl -e shell -MCPAN
#$install Apache::DBI
RUN /opt/otrs/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-user=www-data --otrs-group=www-data --web-group=www-data /opt/otrs

RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf && \
    a2ensite otrs && \
    a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod headers

RUN mkdir -m 700 /etc/mail/authinfo/ && \
    echo "AuthInfo: \"U:otrs\" \"I:$SMTP_USER\" \"P:$SMTP_PASSWORD\"" >  /etc/mail/authinfo/gmail-auth && \
    makemap hash /etc/mail/authinfo/gmail-auth < /etc/mail/authinfo/gmail-auth && \
    echo "define(`SMART_HOST',`[smtp.gmail.com]')dnl
define(`RELAY_MAILER_ARGS', `TCP $h 587')dnl
define(`ESMTP_MAILER_ARGS', `TCP $h 587')dnl
define(`confAUTH_OPTIONS', `A p')dnl
TRUST_AUTH_MECH(`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
define(`confAUTH_MECHANISMS', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
FEATURE(`authinfo',`hash -o /etc/mail/authinfo/gmail-auth.db')dnl" >> /etc/mail/sendmail.mc && \
    make -C /etc/mail && /etc/init.d/sendmail reload

CMD while true && \\
    do && \\
      tail -f /dev/null & wait ${!} && \\
    done
