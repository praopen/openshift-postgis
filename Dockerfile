FROM centos:7

LABEL name="postgres-gis" \
        vendor="rapyuta-robotics" \
      	PostgresVersion="9.5" \
      	PostgresFullVersion="9.5.10" \
        version="7.3" \
        release="1.7.0" \
        build-date="2017-11-15" \
        url="https://rapyuta-robotics.com" \
        summary="Includes PostGIS extensions on top of postgres" \
        description="An identical image of crunchy-postgres with the extra PostGIS packages added for users that require PostGIS." \
        io.k8s.description="postgres-gis container" \
        io.k8s.display-name="Rapyuta postgres-gis container" \
        io.openshift.expose-services="" \
        io.openshift.tags="rapyuta,database"


RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm

RUN yum -y update && yum -y install epel-release
RUN yum -y install armadillo
RUN yum -y update glibc-common \
 && yum -y install bind-utils \
    gettext \
    hostname \
    nss_wrapper \
    openssh-server \
    openssh-clients \
    procps-ng  \
    rsync \
 && yum -y install postgresql96-server postgresql96-contrib postgresql96 \
    R-core libRmath plr96 \
    pgaudit_96 \
    pgbackrest \
    libxml2-devel \
    geos-devel \
    gcc-c++ \
    postgresql96-devel \
    json-c \
 && yum -y clean all

RUN yum install -y wget \
    && wget http://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz \
    && tar -xvf gdal-2.2.3.tar.gz \
    && cd gdal-2.2.3 \
    && ./configure \
    && make -j4\
    && make install

RUN wget http://download.osgeo.org/proj/proj-4.9.3.tar.gz \
    && tar -xvf proj-4.9.3.tar.gz \
    && cd proj-4.9.3 \
    && ./configure \
    && make -j4\
    && make install
    
RUN wget http://download.osgeo.org/postgis/source/postgis-2.4.3.tar.gz \
    && tar -xvf postgis-2.4.3.tar.gz \
    && cd postgis-2.4.3 \
    && ./configure --with-pgconfig=/usr/pgsql-9.6/bin/pg_config \
    && make -j4\
    && make install

ENV PGROOT="/usr/pgsql-9.6"
ENV PG_MODE="master"
ENV PG_PRIMARY_USER="postgres"
ENV PG_MASTER_PASSWORD="postgres"
ENV PG_MASTER_PORT="5432"
ENV PG_USER="postgres"
ENV PG_PASSWORD="postgres"
ENV PG_DATABASE="postgres"
ENV PG_ROOT_PASSWORD="postgres"

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# set up cpm directory
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /backup /recover /backrestrepo /sshd

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
	/pgdata /pgwal /pgconf /backup /recover /backrestrepo

# Link pgbackrest.conf to default location for convenience
RUN ln -sf /pgconf/pgbackrest.conf /etc/pgbackrest.conf

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to allow backup of postgres files
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to
# add volumes for sshd host keys

VOLUME ["/pgconf", "/pgdata", "/pgwal", "/backup", "/recover", "/backrestrepo", "/sshd"]

ADD bin/postgres /opt/cpm/bin
ADD bin/postgres-gis /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf

RUN chmod -R a+rw /var/
RUN cp -r /usr/local/lib/* /lib64/.
USER 26

# open up the postgres port
EXPOSE 5432
CMD ["/opt/cpm/bin/start.sh"]