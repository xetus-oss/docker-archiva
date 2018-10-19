FROM openjdk:8
MAINTAINER Xetus OSS <xetusoss@xetus.com>

# Add the archiva user and group with a specific UID/GUI to ensure
RUN groupadd --gid 1000 archiva && useradd --gid 1000 -g archiva archiva

# Set archiva-base as the root directory we will symlink out of.
ENV ARCHIVA_HOME /archiva
ENV ARCHIVA_BASE /archiva-data

#
# Capture the external resources in two a layers.
# 
ADD resource-retriever.sh /tmp/resource-retriever.sh
RUN chmod +x /tmp/resource-retriever.sh &&\
  /tmp/resource-retriever.sh &&\
  rm /tmp/resource-retriever.sh

#
# Perform all setup actions
#
ADD files /tmp
RUN chmod a+x /tmp/setup.sh && /tmp/setup.sh && rm /tmp/setup.sh

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