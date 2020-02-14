FROM    nginx

COPY    nginx.conf /etc/nginx/nginx.conf

WORKDIR /etc/nginx

EXPOSE  80

CMD     ["nginx", "-g", "daemon off;"]

LABEL   author="Sergej Nowoshilow"
LABEL   maintainer="Sergej Nowoshilow"
LABEL   email="Sergej.Nowoshilow@imp.ac.at"
LABEL   description="This container image contains a small nginx webserver for testing the axolotl-omics web views"
LABEL   version="1.0"