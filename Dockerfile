FROM openjdk:8u121
MAINTAINER Lu Han <lhan@xetus.com>

ENV VERSION 2.2.1

#
# Go get the needed tar/jar we'll installing
#
RUN curl -sSLo /apache-archiva-$VERSION-bin.tar.gz http://archive.apache.org/dist/archiva/$VERSION/binaries/apache-archiva-$VERSION-bin.tar.gz \
  && tar --extract --ungzip --file apache-archiva-$VERSION-bin.tar.gz --directory / \
  && rm /apache-archiva-$VERSION-bin.tar.gz && mv /apache-archiva-$VERSION /opt/archiva \
  && curl -sSLo /opt/archiva/lib/mysql-connector-java-5.1.35.jar http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.35/mysql-connector-java-5.1.35.jar

#
# Adjust ownership and Perform the data directory initialization
#
ADD data_dirs.env /data_dirs.env
ADD init.bash /init.bash
ADD jetty_conf /jetty_conf
# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN useradd -d /opt/archiva/data -m archiva &&\
  cd /opt && chown -R archiva:archiva archiva &&\
  cd / && chown -R archiva:archiva /jetty_conf &&\
  chmod 755 /init.bash &&\
  sync && /init.bash &&\
  sync && rm /init.bash

#
# Add the bootstrap cmd
#
ADD run.bash /run.bash
RUN chmod 755 /run.bash

#
# All data is stored on the root data volume.
USER archiva

VOLUME ["/archiva-data"]

# Standard web ports exposted
EXPOSE 8080/tcp 8443/tcp

ENTRYPOINT ["/run.bash"]
