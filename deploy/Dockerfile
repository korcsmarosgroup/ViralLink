FROM selenium/standalone-chrome-debug:3.13.0
MAINTAINER ViralLink project "balazs.bohar@earlham.ac.uk"

ENV CYTOSCAPE_VERSION 3.7.0

USER root
RUN apt-get update

RUN apt-get -y install default-jdk

RUN echo '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java' >> /etc/environment

ADD *.sh /
RUN /bin/bash /install_base_layer.sh

USER seluser

RUN mkdir /home/seluser/cytoscape
WORKDIR /home/seluser/cytoscape
RUN wget --progress=dot:giga --local-encoding=UTF-8 -v https://github.com/cytoscape/cytoscape/releases/download/$CYTOSCAPE_VERSION/cytoscape-$CYTOSCAPE_VERSION.tar.gz -O cytoscape-$CYTOSCAPE_VERSION.tar.gz

RUN tar -zxvf cytoscape-$CYTOSCAPE_VERSION.tar.gz
RUN rm cytoscape-$CYTOSCAPE_VERSION.tar.gz

RUN echo "/home/seluser/cytoscape/cytoscape-unix-$CYTOSCAPE_VERSION/cytoscape.sh --rest 1234" > /home/seluser/cytoscape/start.sh
RUN chmod 777 /home/seluser/cytoscape/start.sh

WORKDIR /home/seluser
RUN git clone https://github.com/novnc/noVNC.git

USER root
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV PYTHONPATH /home/virallink/

RUN /install_python.sh && /install_r.sh

ADD /pipeline /home/virallink/
WORKDIR /home/virallink

ADD /entry_point.sh /opt/bin/entry_point.sh
ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/bin/bash"]
