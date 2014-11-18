FROM ubuntu:14.04

## Installation
RUN \
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
  echo 'deb http://ftp.igh.cnrs.fr/pub/mariadb/repo/10.0/ubuntu trusty main' > /etc/apt/sources.list.d/mariadb.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
RUN apt-get install supervisor -y

## Configuration
RUN sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf
ADD config/supervisor-mariadb.conf /etc/supervisor/conf.d/mariadb.conf
ADD init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 3306
CMD ["/init.sh"]
