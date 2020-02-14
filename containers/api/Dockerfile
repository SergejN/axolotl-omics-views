FROM    nginx

WORKDIR /tmp
ADD     package.json /tmp/package.json
RUN     npm config set registry http://registry.npmjs.org/
RUN     npm install
RUN     mkdir -p /usr/src/app
RUN     cp -a /tmp/node_modules /usr/src/app

WORKDIR /usr/src/app

ADD     . /usr/src/app

EXPOSE  8080

CMD     [ "npm", "run", "prod" ]

LABEL   author="Sergej Nowoshilow"
LABEL   maintainer="Sergej Nowoshilow"
LABEL   email="Sergej.Nowoshilow@imp.ac.at"
LABEL   description="This container image contains a small proxy server that allows to use Axolotl-Omics API"
LABEL   version="1.0"