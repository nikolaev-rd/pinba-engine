FROM alpine:3.9
MAINTAINER Roman Nikolaev <r.nikolaev@tinkoff.ru>

ENV ALPINE_VERSION 3.9
ENV APORTS_VERSION 3.9.3
ENV PINBA_VERSION 1.1.0
ENV MARIADB_VERSION 10.3.13-r0
ENV JUDY_VERSION 1.0.5
ENV TZ=Europe/Moscow

RUN echo "@stable http://dl-4.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" >> /etc/apk/repositories
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --update \
        bash \		
        libevent \
        mariadb=${MARIADB_VERSION} \
        mariadb-client=${MARIADB_VERSION} \
        protobuf \
        pwgen \
		tzdata -U \
     && rm -rf /var/cache/apk/*

COPY build-pinba.sh /
RUN  chmod +x /build-pinba.sh
RUN  /build-pinba.sh

RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

RUN  mkdir -p  /etc/mysql/conf.d
COPY my.cnf    /etc/mysql/
COPY pinba.cnf /

VOLUME /var/lib/mysql

COPY startup.sh /
RUN chmod +x /startup.sh

EXPOSE 3306 30002/udp

ENTRYPOINT ["/startup.sh"]
