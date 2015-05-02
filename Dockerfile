##
## Docker configuration for CKAN 2.3a, with both Postgres and Solr in the same container. 
## With the DEBUG env var set, it will run in development mode, and it exports both the data
## directory and the source directory, for developing extensions. 
##

## Mostly from the Package install instructions at: 
## http://docs.ckan.org/en/latest/maintaining/installing/install-from-package.html

## Env Vars:
##  ADMIN_USER_PASS
##  ADMIN_USER_EMAIL
##  ADMIN_USER_KEY

FROM ubuntu:14.04

MAINTAINER Eric Busboom <eric@andiegodata.org>

##
## Clean and prepare for installing other packages. 
##

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y language-pack-en
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

RUN apt-get install -y python-dev postgresql libpq-dev   git-core 

RUN apt-get install -y gunicorn wget

# Devel mode requires the less css parser, which requires the following ... 
RUN apt-get -y install nodejs npm
# And the confusion b/t node and nodejs is crazy .. .
RUN cp  /usr/bin/nodejs /usr/bin/node
RUN npm install less nodewatch # foo 3

# Arg, pip is broken on 14.04 .. 

WORKDIR /tmp
RUN wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
RUN python get-pip.py

##
## Install Solr
##

RUN  apt-get -y install openjdk-7-jdk

RUN  mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64 /usr/java/default

RUN apt-get -y install solr-tomcat

##
## Installing CKAN
##

RUN mkdir -p /opt/ckan
WORKDIR /opt/ckan 

RUN pip install -e 'git+https://github.com/okfn/ckan.git#egg=ckan'

RUN pip install -r /opt/ckan/src/ckan/requirements.txt

RUN pip install gevent

RUN mkdir -p /etc/ckan/default

RUN chown -R `whoami` /etc/ckan/

RUN ln -s /opt/ckan/src/ckan/who.ini  /etc/ckan/default/who.ini

RUN cp  /opt/ckan/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml 

##
## Install Postgis
##

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -y update
#RUN apt-get -y install ca-certificates
RUN apt-get -y install wget
RUN wget --quiet --no-check-certificate -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -y upgrade
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
RUN apt-get -y install postgresql-9.3 postgresql-contrib-9.3 postgresql-9.3-postgis-2.1 postgis
RUN echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN service postgresql start && \
    /bin/su postgres -c "createuser -d -s -r -l ckan" && \
    /bin/su postgres -c "psql postgres -c \"ALTER USER ckan WITH ENCRYPTED PASSWORD 'ckan'\"" && \
    /bin/su postgres -c "createdb --template template0 -O ckan ckan -E utf-8" && \
    service postgresql stop
    
RUN echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
RUN echo "port = 5432" >> /etc/postgresql/9.3/main/postgresql.conf


##
## Expose and run
##

# For flagging runtime-initialization completed. 
RUN mkdir /var/run/initialized

RUN mkdir /data

VOLUME /data
VOLUME /opt

# Tomcat / solr
EXPOSE 8080 

# Postgres
EXPOSE 5432 

# CKAN Production
EXPOSE 80

# CKAN Development
EXPOSE 5000



ADD start-ckan.sh /opt/ckan/src/ckan/

# Late in file because it changes a lot. 
ADD production.ini /etc/ckan/default/production.ini

##
## A bit of setup
##

WORKDIR /opt/ckan/src/ckan

RUN service tomcat6 start ; service postgresql start && \
    paster --plugin=ckan db init --config=/etc/ckan/default/production.ini && \
    service postgresql stop && service tomcat6 stop

CMD sh start-ckan.sh
