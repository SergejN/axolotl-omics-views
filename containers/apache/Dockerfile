FROM    httpd:2.4.41

RUN apt-get -y update && \
    apt-get -y install perl libapache2-mod-perl2 

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf


LABEL   author="Sergej Nowoshilow"
LABEL   maintainer="Sergej Nowoshilow"
LABEL   email="Sergej.Nowoshilow@imp.ac.at"
LABEL   description="This container image contains a small nginx webserver for testing the axolotl-omics web views"
LABEL   version="1.0"