FROM ubuntu:14.04
ENV DEBIAN_FRONTEND noninteractive

# Tools
RUN apt-get update && \
    apt-get install runit software-properties-common inotify-tools -y

# MariaDB Installation
ENV MARIADB_VERSION 10.0.19+maria-1~trusty
RUN \
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
  echo 'deb http://ftp.igh.cnrs.fr/pub/mariadb/repo/10.0/ubuntu trusty main' > /etc/apt/sources.list.d/mariadb.list && \
  apt-get update && \
  apt-get install -y mariadb-server=${MARIADB_VERSION}
RUN apt-get install pwgen -y

# Configuration
# listen on all interfaces
RUN sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf
# the mariadb running user is specified in the runit script
RUN sed -i 's/^\(user.*=\smysql\)/# \1/' /etc/mysql/my.cnf
# runit file
ADD files/mariadb.run /etc/sv/mariadb/run
# init files
ADD files/lib/ /opt/container/lib/
ADD files/mariadb.sh /opt/container/services/
ADD files/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 3306
CMD ["/init.sh"]
