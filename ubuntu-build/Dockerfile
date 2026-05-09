FROM ubuntu:24.04


WORKDIR /tmp
COPY . ./

RUN chmod o+x ./build.sh
RUN ./build.sh

CMD ["sleep infinity"]
