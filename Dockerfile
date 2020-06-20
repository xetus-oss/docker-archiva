FROM openjdk:8-jdk-alpine
MAINTAINER Xetus OSS <xetusoss@xetus.com>

# Add the archiva user and group with a specific UID/GUI to ensure
RUN addgroup --gid 1000 archiva &&\
	adduser --system -u 1000 -G archiva archiva &&\
	apk add bash curl

# Set archiva-base as the root directory we will symlink out of.
ENV ARCHIVA_HOME /archiva
ENV ARCHIVA_BASE /archiva-data

# Used to tell the resource-retreiver.sh script
# to build the most recent snapshot.
#
# Only specified in the v2-snapshot branch, and needed
# because we use docker cloud builds.
ENV BUILD_SNAPSHOT_RELEASE true

#
# Capture the external resources in two a layers.
# 
ADD files/resource-retriever.sh /tmp/resource-retriever.sh
RUN chmod +x /tmp/resource-retriever.sh &&\
  /tmp/resource-retriever.sh &&\
  rm /tmp/resource-retriever.sh

# Add local scripts
ADD files /tmp

# Perform most initialization actions in this layer
RUN chmod +x /tmp/resource-retriever.sh &&\
	/tmp/resource-retriever.sh &&\
	rm /tmp/resource-retriever.sh &&\
	chmod +x /tmp/setup.sh &&\
	/tmp/setup.sh &&\
	rm /tmp/setup.sh

# Standard web ports exposted
EXPOSE 8080/tcp

HEALTHCHECK CMD /healthcheck.sh

# Switch to the archiva user
USER archiva

# The volume for archiva
VOLUME /archiva-data

# Use SIGINT for stopping
STOPSIGNAL SIGINT

# Use our custom entrypoint
ENTRYPOINT [ "/entrypoint.sh" ]