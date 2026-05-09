FROM ubuntu-upgraded:24.04

WORKDIR /tmp
COPY . ./

RUN chmod u+x ./install.sh
RUN chmod o+x ./install.sh
RUN ./install.sh

CMD ["startup.sh"]
