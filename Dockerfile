FROM openjdk:8u121
MAINTAINER Lu Han <lhan@xetus.com>

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd archiva && useradd -g archiva archiva

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
  && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
  && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true 

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
ADD init.bash /usr/local/bin
ADD run.bash /usr/local/bin
ADD jetty_conf /jetty_conf

RUN chmod +x /usr/local/bin/init.bash &&\
  chmod +x /usr/local/bin/run.bash &&\
  init.bash &&\
  rm /usr/local/bin/init.bash

#
# Add the bootstrap cmd
#

VOLUME ["/archiva-data"]

# Standard web ports exposted
EXPOSE 8080/tcp 8443/tcp

ENTRYPOINT ["run.bash"]
